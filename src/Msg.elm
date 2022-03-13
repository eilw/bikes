module Msg exposing (Msg(..))

import RemoteData exposing (WebData)
import Station exposing (StationAvailability, StationIdentity)


type Msg
    = FetchedStationIdentities (WebData (List StationIdentity))
    | FetchedStationAvailabilities (WebData (List StationAvailability))
    | UpdateStationAvailabilties
