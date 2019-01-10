import React from "react";
import PropTypes from "prop-types";

export default class FounderBubble extends React.Component {
  constructor(props) {
    super(props);
    this.showTooltip = this.showTooltip.bind(this);
  }

  statusIcon() {
    if (this.props.status === "passed") {
      return "fa fa-check-circle brand-primary";
    } else if (this.props.status === "loading") {
      return "fa fa-refresh fa-spin brand-primary";
    } else {
      return "fa fa-exclamation-circle alert-text";
    }
  }

  statusDescription() {
    let name = this.props.name;
    let status = this.props.status;
    if (status === "loading") {
      return "Fetching target status for " + name + ".";
    } else if (status === "passed") {
      return name + " has passed this target.";
    } else {
      return name + " is yet to pass this target!";
    }
  }

  showTooltip(event) {
    let element = $(event.target.closest("a"));
    element.tooltip({ title: this.statusDescription() });
  }

  hideTooltip(event) {
    let element = $(event.target.closest("a"));
    element.tooltip("dispose");
  }

  render() {
    return (
      <a
        className="founder-dashboard__avatar-wrapper"
        onMouseEnter={this.showTooltip}
        onMouseLeave={this.hideTooltip}
      >
        <div className="founder-dashboard__avatar-check">
          <i className={this.statusIcon()} />
        </div>

        <span dangerouslySetInnerHTML={{ __html: this.props.avatar }} />
      </a>
    );
  }
}

FounderBubble.propTypes = {
  name: PropTypes.string,
  avatar: PropTypes.string,
  status: PropTypes.string
};
