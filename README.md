# indoor_navigation

## What is KID?

KID is a flutter-based application for helping users orientate inside of buildings. It provides the user
with a map (like google maps and the like), with the option to differentiate between the different
floors inside the building.

## How can I use KID?

KID provides the framework for visualising and navigating the building, but it is missing the data
of the building. This has to be provided by you. As soon as you have build the map, you can just
drop the resulting map in the app, build and run the app. No coding needed.

## Creating the map

The app builds upon the [mapsforge_flutter](https://github.com/mikes222/mapsforge_flutter) widget
which uses [mapsforge](https://github.com/mapsforge/mapsforge) which in turn
uses the OpenStreetMap project. So quite a stack to navigate through but good news, its opensource
all the way down.

The general process of creating a mapsforge compatible map is explained
[here](https://github.com/mapsforge/mapsforge/blob/master/docs/MapCreation.md), though it only
describes cropping and converting an existing OSM-Map to the mapsforge format. Additionally, you
want to include your own custom data for the inside of the building which usually is not covered by
the OSM maps. Therefore another guide was written to cover that part and can be found
[here](docs/map-creation.md) in the repository.
