import React from "react";
import PropTypes from "prop-types";

export default class ToggleBarTab extends React.Component {
  constructor(props) {
    super(props);

    this.handleClick = this.handleClick.bind(this);
    this.track = this.loadTrack();
  }

  handleClick() {
    if (this.isActiveTrack()) {
      return;
    }

    this.props.setRootState({ activeTrackId: this.track.id });
  }

  loadTrack() {
    let that = this;

    if (this.props.trackId === "sessions") {
      return {
        id: "sessions",
        name: "Sessions"
      };
    }
    else if (this.props.trackId === "default") {
      return {
        id: "default",
        name: "Targets"
      };
    }

    return _.find(this.props.rootProps.tracks, track => {
      return track.id === that.props.trackId;
    });
  }

  isActiveTrack() {
    return this.props.rootState.activeTrackId === this.track.id;
  }

  labelClasses() {
    let classes = "btn founder-dashboard-togglebar__toggle-btn btn-md m-a-0";
    return this.isActiveTrack() ? classes + " active" : classes;
  }

  render() {
    return (
      <div className={this.labelClasses()} onClick={this.handleClick}>
        {this.track.name.toUpperCase()}
      </div>
    );
  }
}

ToggleBarTab.propTypes = {
  trackId: PropTypes.oneOfType([PropTypes.number, PropTypes.string]),
  rootProps: PropTypes.object.isRequired,
  rootState: PropTypes.object.isRequired,
  setRootState: PropTypes.func.isRequired
};
