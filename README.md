# WillowTreeScrollingTabController

The ScrollingTabController provides a tab based container view with navigational tabs at the top and a swipeable content area below. This component follows a similar design and functionality as the Android tab interface.  The following features are supported: 

* Support for a large number of tabs and view controllers.
* Customizable tab cells, dividers, and delegate callbacks to configure each cell
* Customizable selection indicator
* Dynamic tab sizes
* Customizable tab selection positioning.

## Installation

The preferred method to install is to use CocoaPods 

pod 'WillowTreeScrollingTabController'

## Getting Started

The ScrollingTabController supports instantiation either through InterfaceBuilder or through code and may also easily be subclassed to provide the necessary data and view controllers.  The ScrollingTabControllerExample project shows the basic subclassing method of creating the view controller.  The basic setup involves the following:

1. Provide the controller with the set of view controllers that it will manager through the ```viewControllers``` property.
2. Implement the 


  ```func tabView(tabView: ScrollingTabController, configureTitleCell cell: UICollectionViewCell, atIndex index: Int) -> UICollectionViewCell?```
  
  
    protocol method of ScrollingTabControllerDataSource to provide the titles for the tabs in the view controller.
    


