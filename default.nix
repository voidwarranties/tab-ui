{ stdenv, lib, qmake, qt5, wrapQtAppsHook }: 

stdenv.mkDerivation rec {
  pname = "tab-ui";
  version = "1.0";
  src = ./.;
  buildInputs = [ qt5.full ];
  nativeBuildInputs = [ qmake wrapQtAppsHook ]; 
}
