// features/onboarding/data/onboarding_data.dart
class OnboardingData {
  final String title;
  final String description;
  final String imagePath;
  final String iconData;

  const OnboardingData({
    required this.title,
    required this.description,
    required this.imagePath,
    required this.iconData,
  });

  static List<OnboardingData> get slides => [
    const OnboardingData(
      title: 'Selamat Datang di Famisafe',
      description: 'Aplikasi keamanan anak yang membantu orang tua memantau aktivitas digital anak dengan aman dan mudah.',
      imagePath: 'assets/images/onboarding_1.svg',
      iconData: 'family_restroom',
    ),
    const OnboardingData(
      title: 'Pantau Lokasi Real-time',
      description: 'Ketahui lokasi anak Anda secara real-time dan dapatkan notifikasi saat mereka tiba di tempat tujuan.',
      imagePath: 'assets/images/onboarding_2.svg',
      iconData: 'location_on',
    ),
    const OnboardingData(
      title: 'Keamanan & Privasi Terjamin',
      description: 'Data anak Anda aman dengan enkripsi end-to-end. Hanya keluarga yang dapat mengakses informasi.',
      imagePath: 'assets/images/onboarding_3.svg',
      iconData: 'security',
    ),
    const OnboardingData(
      title: 'Siap Memulai?',
      description: 'Mari bergabung dengan keluarga Anda dan mulai pengalaman digital yang aman bersama Famisafe.',
      imagePath: 'assets/images/onboarding_4.svg',
      iconData: 'rocket_launch',
    ),
  ];
}
