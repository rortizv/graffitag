# 📍 GraffiTag - Plan de Ejecución

## 🟢 FASE 1: Foundation & Auth
- [x] Configuración de carpeta: `Core`, `Features`, `Services`, `Models`, `Views`.
- [x] Integración de Firebase SDK y archivo `GoogleService-Info.plist`.
- [x] Implementación de `AuthService.swift` (Google & Email Auth).
- [x] Configuración de Firebase App Check (DeviceCheck/App Attest).
- [x] Vista de Login/Registro con validación de formularios.
- [x] App language: English

## 🟡 FASE 2: Proximity UI & Location
- [x] `LocationManager.swift` con Swift Concurrency y filtrado de distancia.
- [x] Implementación del `HeartbeatModifier.swift` (Borde con glow animado).
- [x] Lógica de cambio de color (Naranja > 200m, Rojo < 100m) basado en ProximityLevel.
- [x] Vibración háptica con `UIImpactFeedbackGenerator` via `HapticManager`.

## 🟠 FASE 3: Map & Social Data
- [x] `MapView` con MapKit y anotaciones animadas por proximidad.
- [x] `FirestoreService` para lectura en tiempo real de Tags cercanos.
- [x] Perfil de usuario: Lista de "Mis Graffitis" con opción de edición/eliminación.

## 🔴 FASE 4: AR Snapshot & Editor
- [x] `ARCaptureService`: Captura de imagen + Depth Map (LiDAR opcional) + ARWorldMap.
- [x] UI de Editor: Lienzo 2D sobre la captura para pintar con colores y tamaño de pincel.
- [x] Lógica de Proyección: Convertir trazos 2D de la pantalla a coordenadas 3D (raycast).
- [x] Subida de assets (Metadata + Imagen + DepthMap + WorldMap) a Firebase.

## ⚪ FASE 5: Polishing
- [ ] Optimizaciones de memoria para el M1.
- [ ] Manejo de errores de conexión y GPS.

---
## 📋 Pendiente del usuario (mañana)

### Xcode (sin código)
1. Agregar `Privacy - Location When In Use Usage Description` en target → Info
2. Agregar `Privacy - Camera Usage Description` en target → Info
3. Agregar capability **"ARKit"** si Xcode lo pide al compilar Features/AR
4. En Firestore Console → crear índice compuesto:
   - Collection: `tags` | Fields: `authorId ASC`, `createdAt DESC`
5. En Firestore Console → crear índice compuesto:
   - Collection: `tags` | Fields: `latitude ASC` (para queries de proximidad)

### Firebase Console
6. Firestore Rules — permitir lectura pública, escritura solo autenticados:
   ```
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /tags/{tagId} {
         allow read: if true;
         allow create: if request.auth != null;
         allow update, delete: if request.auth != null
           && request.auth.uid == resource.data.authorId;
       }
     }
   }
   ```
7. Storage Rules — misma lógica:
   ```
   rules_version = '2';
   service firebase.storage {
     match /b/{bucket}/o {
       match /tags/{tagId}/{allPaths=**} {
         allow read: if true;
         allow write: if request.auth != null;
       }
     }
   }
   ```
