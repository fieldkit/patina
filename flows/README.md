# Strapi Content Sync and Test Script

This Dart script provides functionality to download content from a Strapi GraphQL API, save it locally, and test the downloaded content for verification.

## Features

TODO: List what your package can do. Maybe include images, gifs, or videos.

## Getting started

TODO: List prerequisites and provide or point to information on how to
start using the package.

## Usage

TODO: Include short and useful examples for package users. Add longer examples
to `/example` folder. 

```dart
const like = 'sample';
```

### Download Content

The script downloads content from a Strapi GraphQL API and saves it to a specified directory. It also downloads images linked within the content.

### Test Content

The script tests the downloaded content to verify its integrity by parsing the markdown and checking for any errors.

### Running the Script

The script can be executed with the following arguments:

- `--test`: Tests the downloaded content for verification.
- `--sync`: Downloads the content from the Strapi API and saves it locally.

To run the script, use the following command in your terminal (from the main folder):

```sh
dart flows/example/sync.dart --test
```

then

```sh
dart flows/example/sync.dart --sync
```
