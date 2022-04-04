module StationTests exposing (..)

import Expect
import Fuzz exposing (float, int, string)
import Json.Decode exposing (decodeValue)
import Json.Encode as Json
import Station exposing (mapToStationMapInfo, stationAvailabilityDecoder, stationIdentityDecoder)
import Test exposing (..)


suite : Test
suite =
    describe "Station Module"
        [ describe "StationIdentity"
            [ fuzz3 string float float "decoder maps to a StationIdentity" <|
                \name lat long ->
                    let
                        stationIdentityJson =
                            Json.object
                                [ ( "station_id", Json.string "id" )
                                , ( "name", Json.string name )
                                , ( "lat", Json.float lat )
                                , ( "lon", Json.float long )
                                ]
                    in
                    decodeValue stationIdentityDecoder stationIdentityJson
                        |> Expect.equal
                            (Ok
                                { stationId = "id"
                                , name = name
                                , latitude = lat
                                , longitude = long
                                }
                            )
            ]
        , describe "StationAvailability"
            [ fuzz3 string int int "decoder maps to a StationAvailability" <|
                \id bikesAvailable docksAvailable ->
                    let
                        stationAvailabilityJson =
                            Json.object
                                [ ( "station_id", Json.string id )
                                , ( "num_bikes_available", Json.int bikesAvailable )
                                , ( "num_docks_available", Json.int docksAvailable )
                                ]
                    in
                    decodeValue stationAvailabilityDecoder stationAvailabilityJson
                        |> Expect.equal
                            (Ok
                                { stationId = id
                                , numBikesAvailable = bikesAvailable
                                , numDocksAvailable = docksAvailable
                                }
                            )
            ]
        , describe "StationMapInfo"
            [ test "mapToStationMapInfo" <|
                \_ ->
                    let
                        stationIdentity =
                            { stationId = "id"
                            , name = "Frogner"
                            , latitude = 10.0
                            , longitude = 30.0
                            }

                        stationAvailability =
                            { stationId = "id"
                            , numBikesAvailable = 10
                            , numDocksAvailable = 1
                            }
                    in
                    mapToStationMapInfo stationIdentity stationAvailability
                        |> Expect.equal
                            { name = "Frogner"
                            , latitude = 10.0
                            , longitude = 30.0
                            , numBikesAvailable = 10
                            , numDocksAvailable = 1
                            }
            ]
        ]
