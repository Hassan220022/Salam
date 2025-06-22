# Salam - Quran Mobile App 🕌

A comprehensive Islamic mobile application built with Flutter, featuring Quran reading, prayer times, AI assistant, and much more. Built with Clean Architecture principles and Material 3 design.

## ✨ Features

### 📖 **Quran Reading**
- Complete Quran with 114 Surahs
- Beautiful Arabic text with multiple translations
- Bookmark verses with personal notes
- Reading progress tracking
- Advanced search (Arabic, English, translation)
- Audio playback with TTS support
- Offline reading capabilities

### 🕌 **Prayer & Islamic Tools**
- Accurate prayer times based on location
- Qibla direction finder
- Hijri calendar integration
- Prayer notifications
- Islamic calendar events

### 🤖 **AI Assistant**
- GPT-4 powered Islamic knowledge assistant
- Answers questions about Islam, Quran, and Hadith
- Constrained to authentic Islamic sources
- Persistent chat history
- Safe and reliable Islamic guidance

### 🎨 **User Experience**
- Material 3 design system
- Multiple theme options (Islamic, Modern, Elegant)
- Comprehensive accessibility features
- Text-to-Speech support (Arabic & English)
- Dark/Light mode support
- Responsive design for all screen sizes

### 🔧 **Advanced Features**
- Offline-first architecture
- Intelligent caching system
- Community features and sharing
- Comprehensive settings management
- Reading progress synchronization
- Bookmark management with search

## 🏗️ Architecture

This app is built using **Clean Architecture** principles with clear separation of concerns:

```
lib/
├── core/           # Core utilities & constants
├── data/           # Data sources, models, repositories
├── domain/         # Business logic, entities, use cases
├── presentation/   # UI screens, widgets, providers
└── services/       # External services & integrations
```

### Key Architectural Patterns:
- **Clean Architecture**: Dependency inversion and separation of concerns
- **Provider Pattern**: State management with clean architecture integration
- **Repository Pattern**: Data abstraction with Result pattern
- **Use Cases**: Business logic encapsulation
- **Dependency Injection**: Proper layer separation

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (>=3.0.0)
- Dart SDK (>=3.0.0)
- Android Studio / VS Code
- iOS development setup (for iOS builds)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/hassan220022/salam.git
   cd salam
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate code (if needed)**
   ```bash
   flutter packages pub run build_runner build
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

### Environment Setup

For AI assistant functionality, create a `.env` file in the root directory:
```env
OPENAI_API_KEY=your_openai_api_key_here
```

## 📱 Screenshots

*Screenshots will be added here showcasing the app's beautiful Material 3 interface*

## 🛠️ Technologies Used

- **Flutter**: Cross-platform mobile development
- **Dart**: Programming language
- **Provider**: State management
- **Hive**: Local database for caching
- **HTTP**: API communication
- **OpenAI API**: AI assistant functionality
- **Geolocator**: Location services
- **flutter_tts**: Text-to-speech
- **shared_preferences**: Local storage
- **flutter_dotenv**: Environment variables

## 📚 API Integration

- **Quran API**: Complete Quran text and translations
- **Prayer Times API**: Accurate prayer calculations
- **OpenAI GPT-4**: Islamic knowledge assistant
- **Geolocation**: Prayer times and Qibla direction

## 🎯 Project Status

✅ **Complete Features:**
- Clean Architecture implementation
- Material 3 UI/UX design
- Quran reading with bookmarks
- Prayer times and notifications
- AI assistant integration
- Comprehensive accessibility
- Offline support
- Advanced caching system

## 🤝 Contributing

We welcome contributions! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Follow the existing code style and architecture patterns
4. Write tests for new functionality
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

### Code Style
- Follow Dart/Flutter conventions
- Maintain clean architecture principles
- Add proper documentation
- Write meaningful commit messages

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Quran API providers for Islamic content
- Flutter team for the amazing framework
- Muslim developers community for inspiration
- OpenAI for AI assistant capabilities

## 📞 Support

For support, questions, or feedback:
- Create an issue in this repository
- Contact: [hassansherif122202@gmail.com](mailto:hassansherif122202@gmail.com)

---

**Made with ❤️ for the Muslim community**

*"And We have certainly made the Quran easy for remembrance, so is there any who will remember?"* - Quran 54:17
