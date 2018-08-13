exception UnexpectedResponse(int);

let handleApiError =
  [@bs.open]
  (
    fun
    | UnexpectedResponse(code) => code
  );

let str = ReasonReact.string;

type state = {te: TimelineEvent.t};

type action =
  | ChangeStatus(TimelineEvent.status);

let component = ReasonReact.reducerComponent("ReviewForm");

let saveStatus = (status, send, _event) => send(ChangeStatus(status));

let handleResponseJSON = (te, markReviewedCB, json) =>
  switch (
    json
    |> Json.Decode.(field("error", nullable(string)))
    |> Js.Null.toOption
  ) {
  | Some(error) => Notification.error("Something went wrong!", error)
  | None =>
    Notification.success(
      "Review Successful",
      "Event reviewed and moved to completed",
    );
    te |> markReviewedCB;
  };

let sendReview =
    (te, reviewedStatus, markReviewedCB, authenticityToken, _event) => {
  Js.log("Submitting Review");
  let payload = Js.Dict.empty();
  Js.Dict.set(
    payload,
    "authenticity_token",
    authenticityToken |> Js.Json.string,
  );
  let statusKey =
    switch (reviewedStatus) {
    | TimelineEvent.NotAccepted => "not_accepted"
    | NeedsImprovement => "needs_improvement"
    | Verified(_grade) => "verified"
    };
  Js.Dict.set(payload, "status", statusKey |> Js.Json.string);
  switch (reviewedStatus) {
  | TimelineEvent.Verified(grade) =>
    Js.Dict.set(
      payload,
      "grade",
      grade |> TimelineEvent.gradeString |> Js.Json.string,
    )
  | NeedsImprovement
  | NotAccepted => ()
  };
  let id = te |> TimelineEvent.id |> string_of_int;
  Js.Promise.(
    Fetch.fetchWithInit(
      "/timeline_events/" ++ id ++ "/review",
      Fetch.RequestInit.make(
        ~method_=Post,
        ~body=
          Fetch.BodyInit.make(Js.Json.stringify(Js.Json.object_(payload))),
        ~headers=Fetch.HeadersInit.make({"Content-Type": "application/json"}),
        ~credentials=Fetch.SameOrigin,
        (),
      ),
    )
    |> then_(response =>
         if (Fetch.Response.ok(response)
             || Fetch.Response.status(response) == 422) {
           response |> Fetch.Response.json;
         } else {
           Js.Promise.reject(
             UnexpectedResponse(response |> Fetch.Response.status),
           );
         }
       )
    |> then_(json =>
         json |> handleResponseJSON(te, markReviewedCB) |> resolve
       )
    |> catch(error =>
         (
           switch (error |> handleApiError) {
           | Some(code) =>
             Notification.error(code |> string_of_int, "Please try again")
           | None =>
             Notification.error("Something went wrong!", "Please try again")
           }
         )
         |> resolve
       )
    |> ignore
  );
};

let idPostfix = status =>
  switch (status) {
  | TimelineEvent.NotReviewed => "pending"
  | Reviewed(reviewedStatus) =>
    switch (reviewedStatus) {
    | TimelineEvent.Verified(_) => "verified"
    | TimelineEvent.NeedsImprovement => "needs-improvement"
    | TimelineEvent.NotAccepted => "not-accepted"
    }
  };

let statusRadioInput = (status, timelineEventId, send) => {
  let inputId =
    "review-form__status-input-"
    ++ (status |> idPostfix)
    ++ "-"
    ++ timelineEventId;
  <div className="form-check form-check-inline">
    <input
      className="form-check-input"
      type_="radio"
      name=("review-form__status-radio-" ++ timelineEventId)
      id=inputId
      onClick=(saveStatus(status, send))
    />
    <label className="form-check-label" htmlFor=inputId>
      (status |> TimelineEvent.statusString |> str)
    </label>
  </div>;
};

let gradeRadioInput = (grade, timelineEventId, send, state) => {
  let inputId =
    "review-form__grade-input-"
    ++ (grade |> TimelineEvent.gradeString)
    ++ "-"
    ++ timelineEventId;
  <div className="form-check form-check-inline">
    <input
      className="form-check-input"
      type_="radio"
      name=("review-form__grade-radio-" ++ timelineEventId)
      id=inputId
      onChange=(saveStatus(TimelineEvent.Reviewed(Verified(grade)), send))
      checked=(
        state.te
        |> TimelineEvent.status == TimelineEvent.Reviewed(Verified(grade))
      )
    />
    <label className="form-check-label" htmlFor=inputId>
      (grade |> TimelineEvent.gradeString |> String.capitalize |> str)
    </label>
  </div>;
};

let make =
    (~timelineEvent, ~replaceTimelineEvent, ~authenticityToken, _children) => {
  ...component,
  initialState: () => {te: timelineEvent},
  reducer: (action, _state) =>
    switch (action) {
    | ChangeStatus(status) =>
      ReasonReact.Update({
        te: timelineEvent |> TimelineEvent.updateStatus(status),
      })
    },
  didUpdate: ({newSelf}) =>
    Js.log(
      "status: "
      ++ (
        newSelf.state.te |> TimelineEvent.status |> TimelineEvent.statusString
      ),
    ),
  render: ({state, send}) => {
    let timelineEventId = state.te |> TimelineEvent.id |> string_of_int;
    <div className="d-flex flex-column">
      <h5 className="timeline-event-card__field-header font-semibold mt-0">
        ("Update Status:" |> str)
      </h5>
      <div className="d-flex flex-column">
        <div className="pb-1">
          (
            statusRadioInput(
              TimelineEvent.Reviewed(Verified(TimelineEvent.Good)),
              timelineEventId,
              send,
            )
          )
        </div>
        <div className="pb-1">
          (
            statusRadioInput(
              TimelineEvent.Reviewed(NeedsImprovement),
              timelineEventId,
              send,
            )
          )
        </div>
        <div className="pb-1">
          (
            statusRadioInput(
              TimelineEvent.Reviewed(NotAccepted),
              timelineEventId,
              send,
            )
          )
        </div>
      </div>
      (
        if (state.te |> TimelineEvent.isVerified) {
          <div className="pt-3">
            <h5 className="timeline-event-card__field-header font-semibold">
              ("Grade:" |> str)
            </h5>
            <div className="js-review-form__grade-radios">
              (
                gradeRadioInput(
                  TimelineEvent.Good,
                  timelineEventId,
                  send,
                  state,
                )
              )
              (
                gradeRadioInput(
                  TimelineEvent.Great,
                  timelineEventId,
                  send,
                  state,
                )
              )
              (
                gradeRadioInput(
                  TimelineEvent.Wow,
                  timelineEventId,
                  send,
                  state,
                )
              )
            </div>
          </div>;
        } else {
          ReasonReact.null;
        }
      )
      (
        switch (state.te |> TimelineEvent.status) {
        | TimelineEvent.NotReviewed => ReasonReact.null
        | Reviewed(reviewedStatus) =>
          <button
            onClick=(
              sendReview(
                state.te,
                reviewedStatus,
                replaceTimelineEvent,
                authenticityToken,
              )
            )
            className="btn btn-ghost-primary mt-2">
            ("Save Review" |> str)
          </button>
        }
      )
    </div>;
  },
};