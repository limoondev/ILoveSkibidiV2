# ILoveSkibidi V2

Application macOS premium avec correction automatique de texte, import Notability et scanner de documents.

## Fonctionnalités

- **Correction Automatique du Texte** — Correction orthographique, grammaticale, guillemets/tirets intelligents, auto-capitalisation. Fonctionne globalement pour toutes les applications via le presse-papiers.

- **Import Notability** — Import automatique de fichiers PDF, images (PNG, JPEG, TIFF), RTF, texte brut, HTML et Markdown directement dans Notability via URL scheme ou Share Sheet.

- **Scanner de Documents** — Capture via appareil photo ou import d'image, avec amélioration automatique (luminosité, contraste, saturation, netteté), modes couleur/N&B/niveaux de gris, et export.

- **UI Premium** — Interface sombre avec dégradés, effets glassmorphism, animations fluides, composants personnalisés.

- **Écran de Chargement** — Animation premium avec particules, dégradé animé, barre de progression et indicateur de chargement.

## Architecture

```
ILoveSkibidiV2/
├── ILoveSkibidiV2App.swift          # Point d'entrée SwiftUI
├── Info.plist                        # Configuration de l'app
├── Assets.xcassets/                  # Assets et icônes
├── Views/
│   ├── LoadingScreenView.swift       # Écran de chargement
│   ├── MainView.swift                # Navigation principale + sidebar
│   ├── TextCorrectionView.swift      # Vue correction de texte
│   ├── NotabilityImportView.swift    # Vue import Notability
│   ├── ScannerView.swift             # Vue scanner de documents
│   └── SettingsView.swift            # Vue réglages
├── Services/
│   ├── TextCorrectionService.swift   # Service de correction NSSpellChecker
│   ├── NotabilityImportService.swift # Service d'import Notability
│   └── ScannerService.swift          # Service de scan CoreImage
├── Components/
│   └── PremiumComponents.swift       # Composants UI réutilisables
└── Extensions/
    └── Color+Theme.swift             # Thème de couleurs
```

## Prérequis

- **macOS 13.0+** (Ventura ou supérieur)
- **Xcode 15.0+**
- **Swift 5.0+**
- **Notability** (installé pour la fonctionnalité d'import)

## Installation

1. Ouvrir `ILoveSkibidi V2.xcodeproj` dans Xcode
2. Sélectionner la cible "ILoveSkibidi V2"
3. Configurer le signing dans l'onglet "Signing & Capabilities"
4. Build & Run (`⌘R`)

## Raccourcis clavier

| Raccourci | Action |
|-----------|--------|
| `⌘⇧C` | Corriger le texte sélectionné |
| `⌘⇧N` | Import Notability |
| `⌘⇧S` | Ouvrir le scanner |
| `⌘⇧E` | Amélioration automatique |

## Langues supportées

Français, English, Deutsch, Español, Italiano

## Version

2.0.0 — Premium Edition
