import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/usuario.dart';
import '../services/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthRepository? repository})
      : _repository = repository ?? SupabaseAuthRepository() {
    try {
      _authSubscription =
          _repository.authStateChanges.listen(_handleAuthStateChange);
      final session = _repository.currentSession;
      if (session != null) unawaited(_loadProfile(session));
    } catch (error) {
      _errorMessage = _messageFor(error);
    }
  }

  final AuthRepository _repository;
  StreamSubscription<AuthSession?>? _authSubscription;

  Usuario? _usuarioActual;
  String? _errorMessage;
  bool _cargando = false;
  int _profileRequest = 0;
  bool _disposed = false;

  Usuario? get usuarioActual => _usuarioActual;
  bool get estaAutenticado => _usuarioActual != null;
  String? get errorMessage => _errorMessage;
  bool get cargando => _cargando;

  Future<bool> registrar(String nombreUsuario, String password) async {
    _setCargando(true);
    _errorMessage = null;
    try {
      final usuario = await _repository.register(nombreUsuario, password);
      _profileRequest++;
      _usuarioActual = usuario;
      notifyListeners();
      return true;
    } catch (error) {
      _errorMessage = _messageFor(error);
      return false;
    } finally {
      _setCargando(false);
    }
  }

  Future<bool> iniciarSesion(String nombreUsuario, String password) async {
    _setCargando(true);
    _errorMessage = null;
    try {
      final usuario = await _repository.login(nombreUsuario, password);
      _profileRequest++;
      _usuarioActual = usuario;
      notifyListeners();
      return true;
    } catch (error) {
      _errorMessage = _messageFor(error);
      return false;
    } finally {
      _setCargando(false);
    }
  }

  Future<void> cerrarSesion() async {
    try {
      await _repository.logout();
      _profileRequest++;
      _usuarioActual = null;
      _errorMessage = null;
      notifyListeners();
    } catch (error) {
      _errorMessage = _messageFor(error);
      notifyListeners();
    }
  }

  void _handleAuthStateChange(AuthSession? session) {
    if (_disposed) return;

    if (session == null) {
      _profileRequest++;
      _usuarioActual = null;
      _errorMessage = null;
      notifyListeners();
      return;
    }

    unawaited(_loadProfile(session));
  }

  Future<void> _loadProfile(AuthSession session) async {
    final request = ++_profileRequest;
    try {
      final usuario = await _repository.loadProfile(session.userId);
      if (_disposed || request != _profileRequest) return;
      _usuarioActual = usuario;
      _errorMessage = null;
      notifyListeners();
    } catch (error) {
      if (_disposed || request != _profileRequest) return;
      _usuarioActual = null;
      _errorMessage = _messageFor(error);
      notifyListeners();
    }
  }

  String _messageFor(Object error) {
    if (error is AuthRepositoryException) return error.userMessage;
    return AuthFailure.unexpected.userMessage;
  }

  void _setCargando(bool valor) {
    if (_disposed) return;
    _cargando = valor;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    final subscription = _authSubscription;
    if (subscription != null) unawaited(subscription.cancel());
    super.dispose();
  }
}
