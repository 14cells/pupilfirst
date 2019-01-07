import React from "react";
import PropTypes from "prop-types";
import SubmitButton from "./SubmitButton";
import ImageButton from "./ImageButton";
import DatePicker from "./DatePicker";

export default class ActionBar extends React.Component {
  constructor(props) {
    super(props);

    this.showLinkForm = this.showLinkForm.bind(this);
    this.showFileForm = this.showFileForm.bind(this);
    this.showDateForm = this.showDateForm.bind(this);
    this.disableTab = this.disableTab.bind(this);
    this.handleDate = this.handleDate.bind(this);
    this.state = {
      dateFormVisible: false
    };
  }

  componentDidUpdate() {
    if (this.props.showDateError) {
      $(".date-of-event").popover("show");
    } else {
      $(".date-of-event").popover("hide");
    }
  }
  formLinkClasses(type) {
    let classes = "";

    if (type == "link") {
      classes = "timeline-builder__upload-section-tab link-upload";
      classes += this.props.attachmentAllowed ? "" : " action-tab-disabled";
    } else if (type == "file") {
      classes = "timeline-builder__upload-section-tab file-upload";
      classes += this.props.attachmentAllowed ? "" : " action-tab-disabled";
    } else {
      classes = "timeline-builder__upload-section-tab date-of-event";
      classes += this.disableTab() ? " action-tab-disabled" : "";
    }

    if (this.props.currentForm == type) {
      classes += " timeline-builder__active-tab";
    }

    return classes;
  }

  showLinkForm() {
    if (this.props.attachmentAllowed) {
      this.props.formClickedCB("link");
    }
  }

  showFileForm() {
    if (this.props.attachmentAllowed) {
      this.props.formClickedCB("file");
    }
  }

  handleDate(date) {
    this.setState({ dateFormVisible: false });
    this.props.addAttachmentCB("date", {
      value: date
    });
  }

  showDateForm() {
    if (this.state.dateFormVisible) {
      this.setState({ dateFormVisible: false });
    } else {
      this.props.resetErrorsCB();
      this.setState({ dateFormVisible: true });
    }
  }

  dateLabel() {
    if (this.props.selectedDate != null) {
      let date = moment(this.props.selectedDate, "YYYY-MM-DD");
      return date.format("MMM D");
    } else {
      return "Date";
    }
  }

  disableTab() {
    return this.props.submissionProgress != null;
  }

  render() {
    return (
      <div className="timeline-builder__submit-tabs">
        <div className="timeline-builder__upload-section">
          <ImageButton
            key={this.props.imageButtonKey}
            coverImage={this.props.coverImage}
            addDataCB={this.props.addDataCB}
            disabled={this.disableTab()}
          />
          <div
            className={this.formLinkClasses("link")}
            onClick={this.showLinkForm}
          >
            <i className="timeline-builder__upload-section-icon fa fa-link" />
            <span className="timeline-builder__tab-label">Link</span>
          </div>
          <div
            className={this.formLinkClasses("file")}
            onClick={this.showFileForm}
          >
            <i className="timeline-builder__upload-section-icon fa fa-file-text-o" />
            <span className="timeline-builder__tab-label">File</span>
          </div>

          <div className="timeline-builder__date-picker-popup">
            {this.state.dateFormVisible && (
              <DatePicker handleDate={this.handleDate} />
            )}
          </div>
          <div
            className={this.formLinkClasses("date")}
            onClick={this.showDateForm}
            data-toggle="popover"
            data-title="Date Missing!"
            data-content="Please select a date for the event."
            data-placement="bottom"
            data-trigger="manual"
          >
            <i className="timeline-builder__upload-section-icon fa fa-calendar" />
            <span className="timeline-builder__tab-label">
              {this.dateLabel()}
            </span>
          </div>
        </div>
        <div className="d-flex timeline-builder__select-section">
          <SubmitButton
            submissionProgress={this.props.submissionProgress}
            submitCB={this.props.submitCB}
            submissionError={this.props.submissionError}
            submissionSuccessful={this.props.submissionSuccessful}
          />
        </div>
      </div>
    );
  }
}

ActionBar.propTypes = {
  formClickedCB: PropTypes.func,
  currentForm: PropTypes.string,
  submitCB: PropTypes.func,
  coverImage: PropTypes.object,
  addDataCB: PropTypes.func,
  imageButtonKey: PropTypes.string,
  selectedDate: PropTypes.string,
  addAttachmentCB: PropTypes.func,
  submissionProgress: PropTypes.number,
  submissionError: PropTypes.string,
  submissionSuccessful: PropTypes.bool,
  attachmentAllowed: PropTypes.bool,
  showDateError: PropTypes.bool,
  showEventTypeError: PropTypes.bool,
  resetErrorsCB: PropTypes.func,
};
