# 📍 GraffiTag - Plan de Ejecución

## 🟢 FASE 1: Foundation & Auth
- [x] Configuración de carpeta: `Core`, `Features`, `Services`, `Models`, `Views`.
- [x] Integración de Firebase SDK y archivo `GoogleService-Info.plist`.
- [x] Implementación de `AuthService.swift` (Google & Email Auth).
- [ ] Configuración de Firebase App Check (DeviceCheck/App Attest).
- [ ] Vista de Login/Registro con validación de formularios.
- [ ] App language: English

## 🟡 FASE 2: Proximity UI & Location
- [ ] `LocationManager.swift` con Swift Concurrency y filtrado de distancia.
- [ ] Implementación del `HeartbeatModifier.swift` (Borde con glow animado).
- [ ] Lógica de cambio de color (Naranja > 200m, Rojo < 100m) basado en coordenadas de Firestore.
- [ ] Vibración háptica con `UIImpactFeedbackGenerator`.

## 🟠 FASE 3: Map & Social Data
- [ ] `MapView` con MapKit y Clustering de anotaciones.
- [ ] `FirestoreService` para lectura en tiempo real de Tags cercanos.
- [ ] Perfil de usuario: Lista de "Mis Graffitis" con opción de edición.

## 🔴 FASE 4: AR Snapshot & Editor
- [ ] `ARCaptureService`: Captura de imagen + Depth Map (LiDAR) + ARWorldMap.
- [ ] UI de Editor: Lienzo 2D sobre la captura para pintar.
- [ ] Lógica de Proyección: Convertir trazos 2D de la pantalla a coordenadas 3D espaciales.
- [ ] Subida de assets (Metadata + Imagen de referencia) a Firebase.

## ⚪ FASE 5: Polishing
- [ ] Optimizaciones de memoria para el M1.
- [ ] Manejo de errores de conexión y GPS.
