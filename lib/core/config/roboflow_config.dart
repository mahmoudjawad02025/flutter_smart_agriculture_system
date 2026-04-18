class RoboflowConfig {
  const RoboflowConfig();

  String get baseUrl => 'https://serverless.roboflow.com';
  String get apiKey => 'i0xS9UzBPPMoZmjwDApN';
  String get workspaceName => 'main-account';

  // Use the exact workflow id slug from your Roboflow dashboard if needed.
  String get workflowId => 'General Segmentation API 2';

  String get classes => 'bệnh sương mai, bệnh-khảm, bệnh-phấn-trắng';
}
