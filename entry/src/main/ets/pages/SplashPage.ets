import LottieAnimation from '../animation/LottieAnimation';
import { ConstantUI } from '../util/ConstantUI';
import { DetailPageBuilder } from './DetailPage';
import { HistoryPageBuilder } from './HistoryPage';
import { IndexPageBuilder } from './Index';

@Entry
@Component
export struct SplashPage {
  @Provide('navPathStack') navPathStack: NavPathStack = new NavPathStack();

  aboutToAppear() {
    setTimeout(() => {
      this.navPathStack.replacePathByName('Index', null);
    }, 5000);
  }

  @Builder
  PageMap(name: string) {
    if (name === 'Index') {
      IndexPageBuilder();
    } else if (name === 'DetailPage') {
      DetailPageBuilder()
    } else if(name === 'HistoryPage') {
      HistoryPageBuilder()
    }
  }

  build() {
    Navigation(this.navPathStack) {
      Column() {
        LottieAnimation({ politeChickyPath: 'resources/rawfile/swimmer.json' })
          .width(ConstantUI.FULL_WIDTH)
          .height(ConstantUI.FULL_HEIGHT)
      }
      .width(ConstantUI.FULL_WIDTH)
      .height(ConstantUI.FULL_HEIGHT)
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
    }
    .width(ConstantUI.FULL_WIDTH)
    .height(ConstantUI.FULL_HEIGHT)
    .mode(NavigationMode.Stack)
    .hideTitleBar(true)
    .hideBackButton(true)
    .ignoreLayoutSafeArea()
    .navDestination(this.PageMap)
    .titleMode(NavigationTitleMode.Mini)
  }
}
