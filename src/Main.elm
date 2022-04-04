module Main exposing (..)

import Accessibility.Styled as Html exposing (Html)
import Browser
import CityBikesApi
import Css
import Html.Styled
import Html.Styled.Attributes as Attributes
import Http
import List.Extra
import Maybe.Extra
import Msg exposing (Msg(..))
import Ports
import Process
import RemoteData exposing (RemoteData, WebData)
import Station exposing (StationAvailability, StationIdentity, StationMapInfo)
import Task



---- MODEL ----


type alias Model =
    { identities : WebData (List StationIdentity)
    , availabilities : WebData (List StationAvailability)
    }


init : ( Model, Cmd Msg )
init =
    ( { identities = RemoteData.Loading
      , availabilities = RemoteData.Loading
      }
    , Cmd.batch
        [ CityBikesApi.getStationIdentities
        , CityBikesApi.getStationAvailabilities
        , Ports.initialiseMapPort ()
        ]
    )



---- UPDATE ----


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        FetchedStationIdentities response ->
            let
                updatedModel =
                    { model | identities = response }
            in
            ( updatedModel
            , Cmd.batch
                [ handlePotentialError response
                , plotStationsOnMap updatedModel
                ]
            )

        FetchedStationAvailabilities response ->
            let
                updatedModel =
                    { model | availabilities = response }
            in
            ( updatedModel
            , Cmd.batch
                [ handlePotentialError response
                , plotStationsOnMap updatedModel
                , scheduleUpdateStationAvailabilities
                ]
            )

        UpdateStationAvailabilties ->
            ( model
            , CityBikesApi.getStationAvailabilities
            )


plotStationsOnMap : Model -> Cmd Msg
plotStationsOnMap model =
    case ( model.identities, model.availabilities ) of
        ( RemoteData.Success identities, RemoteData.Success availabilities ) ->
            mapAllStationsToMapInfo identities availabilities
                |> Ports.addStationsDetailsToMap

        ( RemoteData.Success identities, RemoteData.Failure _ ) ->
            Ports.addStationsToMap identities

        ( _, _ ) ->
            Cmd.none


mapAllStationsToMapInfo : List StationIdentity -> List StationAvailability -> List StationMapInfo
mapAllStationsToMapInfo identities availabilities =
    identities
        |> List.map (matchStationDataToBuildStationMapInfo availabilities)
        |> Maybe.Extra.values


matchStationDataToBuildStationMapInfo : List StationAvailability -> StationIdentity -> Maybe StationMapInfo
matchStationDataToBuildStationMapInfo availabilities identity =
    findAvailabilityForStationId availabilities identity.stationId
        |> Maybe.map (\availability -> Station.mapToStationMapInfo identity availability)


findAvailabilityForStationId : List StationAvailability -> String -> Maybe StationAvailability
findAvailabilityForStationId availabilities stationId =
    List.Extra.find (\availability -> availability.stationId == stationId) availabilities


scheduleUpdateStationAvailabilities : Cmd Msg
scheduleUpdateStationAvailabilities =
    Process.sleep timeUntilNextUpdateInMs
        |> Task.perform (always UpdateStationAvailabilties)


timeUntilNextUpdateInMs : Float
timeUntilNextUpdateInMs =
   30000


handlePotentialError : RemoteData Http.Error a -> Cmd Msg
handlePotentialError response =
    case response of
        RemoteData.Failure error ->
            Debug.log ("Response failed - " ++ buildErrorLogMessage error) Cmd.none

        _ ->
            Cmd.none


buildErrorLogMessage : Http.Error -> String
buildErrorLogMessage httpError =
    case httpError of
        Http.BadUrl message ->
            "BadUrl: " ++ message

        Http.Timeout ->
            "Timeout"

        Http.NetworkError ->
            "NetworkError"

        Http.BadStatus statusCode ->
            "BadStatusRequest failed with status code: " ++ String.fromInt statusCode

        Http.BadBody message ->
            "Badbody: " ++ message



---- VIEW ----


view : Model -> Html msg
view model =
    Html.section []
        [ Html.h1 [] [ Html.text "Bysykkelstasjoner" ]
        , mapContainer
        , showListOfStations model
        ]


mapContainer : Html msg
mapContainer =
    Html.div
        [ Attributes.id "mapContainer"
        , Attributes.css
            [ Css.width <| Css.vh 100
            , Css.height <| Css.vh 60
            , Css.margin2 Css.zero Css.auto
            ]
        ]
        []


showListOfStations : Model -> Html msg
showListOfStations model =
    Html.div [ Attributes.css [ Css.marginTop <| Css.px 24 ] ]
        [ case ( model.identities, model.availabilities ) of
            ( RemoteData.Success identitiesResponse, _ ) ->
                Html.div []
                    [ showPotentialErrorMessageForAvailabilities model.availabilities
                    , showStations identitiesResponse model.availabilities
                    ]

            ( RemoteData.Loading, _ ) ->
                Html.text "Laster inn stasjoner"

            ( RemoteData.Failure _, _ ) ->
                Html.text "Noe gikk galt. Fikk ikke hentet stasjonene."

            ( RemoteData.NotAsked, _ ) ->
                Html.text ""
        ]


showPotentialErrorMessageForAvailabilities : WebData (List StationAvailability) -> Html msg
showPotentialErrorMessageForAvailabilities availabilities =
    Html.div [ Attributes.css [ Css.marginBottom <| Css.px 12 ] ]
        [ case availabilities of
            RemoteData.Loading ->
                Html.text "Laster inn tilgjengelig sykler..."

            RemoteData.Failure _ ->
                Html.text "Noe gikk galt. Fikk ikke hentet informasjon om tilgjengelig sykler."

            _ ->
                Html.text ""
        ]


showStations : List StationIdentity -> WebData (List StationAvailability) -> Html msg
showStations identities availabilities =
    let
        sortedStationsByName =
            List.sortBy .name identities
    in
    Html.div [] (List.map (\identity -> showStation identity availabilities) sortedStationsByName)


showStation : StationIdentity -> WebData (List StationAvailability) -> Html msg
showStation stationIdentity availabilities =
    Html.div
        [ Attributes.css
            [ Css.marginBottom <| Css.px 18 ]
        ]
        [ showStationName stationIdentity.name
        , showStationAvailability stationIdentity.stationId availabilities
        ]


showStationName : String -> Html msg
showStationName name =
    Html.span
        [ Attributes.css
            [ Css.fontWeight Css.bold
            ]
        ]
        [ Html.text name
        ]


showStationAvailability : String -> WebData (List StationAvailability) -> Html msg
showStationAvailability stationId availabilities =
    let
        receivedAvailabilities =
            case availabilities of
                RemoteData.Success response ->
                    response

                _ ->
                    []

        maybeAvailability =
            findAvailabilityForStationId receivedAvailabilities stationId
    in
    case maybeAvailability of
        Just availability ->
            Html.div []
                [ Html.div []
                    [ Html.text ("Sykler: " ++ String.fromInt availability.numBikesAvailable)
                    ]
                , Html.div
                    [ Attributes.css [ Css.marginLeft <| Css.px 6 ]
                    ]
                    [ Html.text ("Ledige plasser: " ++ String.fromInt availability.numDocksAvailable) ]
                ]

        Nothing ->
            Html.text ""



---- PROGRAM ----


main : Program () Model Msg
main =
    Browser.element
        { view = view >> Html.Styled.toUnstyled
        , init = \_ -> init
        , update = update
        , subscriptions = always Sub.none
        }
