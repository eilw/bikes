module Main exposing (..)

import Accessibility.Styled as Html exposing (Html)
import Browser
import CityBikesApi
import Css
import Html.Styled
import Html.Styled.Attributes as Attributes
import Http
import List.Extra exposing (find)
import Msg exposing (Msg(..))
import Process
import RemoteData exposing (RemoteData, WebData)
import Station exposing (StationAvailability, StationIdentity)
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
        ]
    )



---- UPDATE ----


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        FetchedStationIdentities response ->
            ( { model | identities = response }
            , handlePotentialError response
            )

        FetchedStationAvailabilities response ->
            ( { model | availabilities = response }
            , Cmd.batch
                [ handlePotentialError response
                , scheduleUpdateStationAvailabilities
                ]
            )

        UpdateStationAvailabilties ->
            ( model
            , CityBikesApi.getStationAvailabilities
            )


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


view : Model -> Html Msg
view model =
    Html.section []
        [ Html.h1 [] [ Html.text "Bysykkelstasjoner" ]
        , showPage model
        ]


showPage : Model -> Html Msg
showPage model =
    case ( model.identities, model.availabilities ) of
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


showPotentialErrorMessageForAvailabilities : WebData (List StationAvailability) -> Html Msg
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


showStations : List StationIdentity -> WebData (List StationAvailability) -> Html Msg
showStations identities availabilities =
    let
        sortedStationsByName =
            List.sortBy .name identities
    in
    Html.div [] (List.map (\identity -> showStation identity availabilities) sortedStationsByName)


showStation : StationIdentity -> WebData (List StationAvailability) -> Html Msg
showStation stationIdentity availabilities =
    Html.div
        [ Attributes.css
            [ Css.marginBottom <| Css.px 18 ]
        ]
        [ showStationName stationIdentity.name
        , showStationAvailability stationIdentity.stationId availabilities
        ]


showStationName : String -> Html Msg
showStationName name =
    Html.span
        [ Attributes.css
            [ Css.fontWeight Css.bold
            ]
        ]
        [ Html.text name
        ]


showStationAvailability : String -> WebData (List StationAvailability) -> Html Msg
showStationAvailability stationId availabilities =
    let
        receivedAvailabilities =
            case availabilities of
                RemoteData.Success response ->
                    response

                _ ->
                    []

        maybeAvailability =
            find (\s -> s.stationId == stationId) receivedAvailabilities
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
