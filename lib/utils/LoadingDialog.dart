import 'package:flutter_easyloading/flutter_easyloading.dart';

class LoadingDialog{

  void showDefaultLoading(String loadingText) {
    print(loadingText);
    EasyLoading.show(
      status: loadingText,
      maskType: EasyLoadingMaskType.black,
    );
  }

  void showProgressLoading(double progress,String loadingText) {
    EasyLoading.showProgress(progress,
      status: loadingText,
      maskType: EasyLoadingMaskType.black,
    );
  }

  void showSuccessMessage(String loadingText) {
    EasyLoading.showSuccess(loadingText,
      maskType: EasyLoadingMaskType.black,
    );
  }

  void showErrorMessage(String loadingText) {
    EasyLoading.showError(loadingText,
      maskType: EasyLoadingMaskType.black,
    );
  }


  void showInfoMessage(String loadingText) {
    EasyLoading.showInfo(loadingText,
      maskType: EasyLoadingMaskType.black,
    );
  }

  void showError(String text){
    EasyLoading.showError(text,
      maskType: EasyLoadingMaskType.black,
    );
  }

  void dismiss(){
    EasyLoading.dismiss();
  }

}
