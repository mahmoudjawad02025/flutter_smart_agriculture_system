class RoboflowConfig {
  const RoboflowConfig();

  String get baseUrl => 'https://detect.roboflow.com';

  // --------------------------------------------------------------------------- cucumber
  // ___
  // String get apiKey => 'i0xS9UzBPPMoZmjwDApN';
  // String get modelId => 'cucumber_disease-h6g5v-qln4v/6';

  // ___
  // String get apiKey => '23E4YGJd3x5w1uujdITS';
  // String get modelId => 'train_cucumber_combinations-okase/1';

  // //
  String get apiKey => 'OlDlihsPyNA5cvxAvaIP';
  String get modelId => 'train_cucumber_combinations_lll-2ima3/1';

  // --------------------------------------------------------------------------- tomato
  // ___
  // String get apiKey => 'i0xS9UzBPPMoZmjwDApN';
  // String get modelId => 'zekeriya_tomato_disease_model/1';

  // my tomate 1 - healthy / Tomato_Bacterial_spot / Tomato Yellow Leaf Curl
  // String get apiKey => '23E4YGJd3x5w1uujdITS';
  // String get modelId => 'tomato1-rwrej/1';

  // ___my tomate 1 - healthy / Tomato_Bacterial_spot / tomato leaf late blight
  // String get apiKey => 'i0xS9UzBPPMoZmjwDApN';
  // String get modelId => 'tomato2-xyz123/1';
}

// dart pub global activate flutterfire_cli
// flutterfire configure --project=smart-cucumber-agriculture
