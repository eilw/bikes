module CityBikesApi exposing (getStationAvailabilities, getStationIdentities)

import Http as Http exposing (expectJson)
import Json.Decode as Decode exposing (Decoder)
import Msg exposing (Msg(..))
import RemoteData
import Station exposing (StationAvailability, StationIdentity, stationAvailabilityDecoder, stationIdentityDecoder)


getStationIdentities : Cmd Msg
getStationIdentities =
    Http.request
        { method = "GET"
        , headers = headers
        , url = stationInformationUrl
        , body = Http.emptyBody
        , expect = expectJson (RemoteData.fromResult >> FetchedStationIdentities) stationInformationResponseDecoder
        , timeout = Nothing
        , tracker = Nothing
        }


getStationAvailabilities : Cmd Msg
getStationAvailabilities =
    Http.request
        { method = "GET"
        , headers = headers
        , url = stationStatusUrl
        , body = Http.emptyBody
        , expect = expectJson (RemoteData.fromResult >> FetchedStationAvailabilities) decodeStationStatusResponse
        , timeout = Nothing
        , tracker = Nothing
        }


headers : List Http.Header
headers =
    [ Http.header "Accept" "application/json"
    , Http.header "Client-Identifier" "EirikWiig - BysykkelTesting"
    ]


stationInformationResponseDecoder : Decoder (List StationIdentity)
stationInformationResponseDecoder =
    Decode.field "data" <|
        Decode.field "stations" <|
            Decode.list stationIdentityDecoder


decodeStationStatusResponse : Decoder (List StationAvailability)
decodeStationStatusResponse =
    Decode.field "data" <|
        Decode.field "stations" <|
            Decode.list stationAvailabilityDecoder


stationInformationUrl : String
stationInformationUrl =
    osloCityBikeApiUrl ++ "station_information.json"


stationStatusUrl : String
stationStatusUrl =
    osloCityBikeApiUrl ++ "station_status.json"


osloCityBikeApiUrl : String
osloCityBikeApiUrl =
    "https://gbfs.urbansharing.com/oslobysykkel.no/"
