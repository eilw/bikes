port module Ports exposing (addStationsDetailsToMap, addStationsToMap, initialiseMapPort)

import Station exposing (StationIdentity, StationMapInfo)


port initialiseMapPort : () -> Cmd msg


port addStationsDetailsToMap : List StationMapInfo -> Cmd msg


port addStationsToMap : List StationIdentity -> Cmd msg
