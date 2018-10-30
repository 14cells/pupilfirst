import React from "react";
import PropTypes from "prop-types";
import starsForScore from "./shared/starsForScore";

export default class TargetStatusBadge extends React.Component {
  containerClasses() {
    let classes =
      "founder-dashboard-target-status-badge__container badge badge-pill";
    let statusClass = this.props.target.status.replace("_", "-");
    classes += " " + statusClass;
    return classes;
  }

  statusIconClasses() {
    return {
      complete: "fa fa-thumbs-o-up",
      needs_improvement: "fa fa-line-chart",
      submitted: "fa fa-hourglass-half",
      pending: "fa fa-clock-o",
      unavailable: "fa fa-lock",
      not_accepted: "fa fa-thumbs-o-down",
      level_locked: "fa fa-eye",
      pending_milestone: "fa fa-lock"
    }[this.props.target.status];
  }

  statusString() {
    return {
      complete: "Completed",
      needs_improvement: "Needs Improvement",
      submitted: "Submitted",
      pending: "Pending",
      unavailable: "Locked",
      not_accepted: "Not Accepted",
      level_locked: "Preview",
      pending_milestone: "Locked"
    }[this.props.target.status];
  }

  statusContents() {
    let grade = ["good", "great", "wow"].indexOf(this.props.target.grade) + 1;
    let score = parseFloat(this.props.target.score);

    if (this.props.target.status !== "complete" || grade === 0) {
      return (
        <span>
          <span className="founder-dashboard-target-header__status-badge-icon">
            <i className={this.statusIconClasses()} />
          </span>

          <span>{this.statusString()}</span>
        </span>
      );
    } else {
      const stars = starsForScore(score, this.props.target.id);

      let gradeString =
        this.props.target.grade.charAt(0).toUpperCase() +
        this.props.target.grade.slice(1);

      return (
        <span>
          {stars} {gradeString}!
        </span>
      );
    }
  }

  render() {
    return (
      <div className={this.containerClasses()}>{this.statusContents()}</div>
    );
  }
}

TargetStatusBadge.propTypes = {
  target: PropTypes.object
};
