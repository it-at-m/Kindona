# Kindona

Kindona is a flutter-based application for helping users orientate inside of buildings. It provides the user
with a map (similar google maps and the like), with the option to differentiate between the different
floors inside the building.

## Table of Contents
- [How can I use Kindona?](#how-can-i-use-kindona)
- [Creating the map](#creating-the-map)
- [Features](#features)
- [How to build](#how-to-build)
- [Contributing](#contributing)
- [License](#license)
- [Contact](#contact)

## How can I use Kindona?

Kindona provides the framework for visualising and navigating the building, but it is missing the data
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

## Features

* Map of the building
* Floor selection for detailed view
* Room search
* Path finding between rooms
* Showing your current location
* Path finding between your current location and a room
* Displaying room information (WIP)

## How to build

The application is based on [flutter](https://flutter.dev/) which is required to build the app.
Once flutter is properly set up you can run the app with

```
flutter run
```

### Target platforms

The primary development platform is android.

iOS and web compatibility is planned

## Contributing

Contributions are what make the open source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

If you have a suggestion that would make this better, please open an issue with the tag "enhancement", fork the repo and create a pull request. You can also simply open an issue with the tag "enhancement".

1. Open an issue with the tag "enhancement"
2. Fork the Project
3. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
4. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
5. Push to the Branch (`git push origin feature/AmazingFeature`)
6. Open a Pull Request

The Flutter Team has a great guide [here](https://docs.flutter.dev/get-started/install) how to set up everything needed.

We also would suggest looking into the Flutter Team's style guide [here](https://github.com/flutter/flutter/wiki/Style-guide-for-Flutter-repo)

More about this in the [CODE_OF_CONDUCT](/CODE_OF_CONDUCT.md) file.


## License

Distributed under the MIT License. See [LICENSE](LICENSE) file for more information.


## Contact

it@M - opensource@muenchen.de