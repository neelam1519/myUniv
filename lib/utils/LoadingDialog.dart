import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class LoadingDialog{
  static final GlobalKey<State> _keyLoader = GlobalKey<State>();


  void showDefaultLoading(String loadingText) {
    print(loadingText);
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
