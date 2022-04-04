module Station exposing
    ( StationAvailability
    , StationIdentity
    , StationMapInfo
    , mapToStationMapInfo
    , stationAvailabilityDecoder
    , stationIdentityDecoder
    )

import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as DecodePipeline


type alias StationIdentity =
    { stationId : String
    , name : String
    , latitude : Float
    , longitude : Float
    }


type alias StationAvailability =
    { stationId : String
    , numBikesAvailable : Int
    , numDocksAvailable : Int
    }


type alias StationMapInfo =
    { name : String
    , latitude : Float
    , longitude : Float
    , numBikesAvailable : Int
    , numDocksAvailable : Int
    }


mapToStationMapInfo : StationIdentity -> StationAvailability -> StationMapInfo
mapToStationMapInfo identity availability =
    { name = identity.name
    , latitude = identity.latitude
    , longitude = identity.longitude
    , numBikesAvailable = availability.numBikesAvailable
    , numDocksAvailable = availability.numDocksAvailable
    }


stationIdentityDecoder : Decoder StationIdentity
stationIdentityDecoder =
    Decode.succeed StationIdentity
        |> DecodePipeline.required "station_id" Decode.string
        |> DecodePipeline.required "name" Decode.string
        |> DecodePipeline.required "lat" Decode.float
        |> DecodePipeline.required "lon" Decode.float


stationAvailabilityDecoder : Decoder StationAvailability
stationAvailabilityDecoder =
    Decode.succeed StationAvailability
        |> DecodePipeline.required "station_id" Decode.string
        |> DecodePipeline.required "num_bikes_available" Decode.int
        |> DecodePipeline.required "num_docks_available" Decode.int
