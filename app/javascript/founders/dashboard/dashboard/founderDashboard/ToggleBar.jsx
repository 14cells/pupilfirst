import React from "react";
import PropTypes from "prop-types";
import ToggleBarTab from "./ToggleBarTab";

export default class ToggleBar extends React.Component {
  constructor(props) {
    super(props);

    this.openTimelineBuilder = this.openTimelineBuilder.bind(this);
    this.hasSessions = this.hasSessions.bind(this);
  }

  openTimelineBuilder() {
    this.props.setRootState({
      timelineBuilderVisible: true,
      timelineBuilderParams: {
        targetId: null,
      }
    });
  }

  tabsForTracks() {
    return this.props.availableTrackIds.map(trackId => {
      return (
        <ToggleBarTab
          key={trackId}
          trackId={trackId}
          rootProps={this.props.rootProps}
          rootState={this.props.rootState}
          setRootState={this.props.setRootState}
        />
      );
    }, this);
  }

  hasSessions() {
    return _.some(this.props.rootProps.targetGroups, ['name', 'Sessions'])
  }

  render() {
    if (this.props.availableTrackIds.length < 2 && !this.hasSessions()) {
      return null;
    }

    return (
      <div className="d-flex justify-content-between justify-content-md-center founder-dashboard-togglebar__container">
        <div className="founder-dashboard-togglebar__toggle">
          <div
            className="btn-group founder-dashboard-togglebar__toggle-group"
            role="group"
          >
            <ToggleBarTab
              level={this.props.rootState.selectedLevel}
              rootProps={this.props.rootProps}
              rootState={this.props.rootState}
              setRootState={this.props.setRootState}
            />
            <ToggleBarTab
              level={this.props.rootProps.levels.find(level => {return level.number === 0;})}
              rootProps={this.props.rootProps}
              rootState={this.props.rootState}
              setRootState={this.props.setRootState}
            />
          </div>
        </div>

        {this.props.currentLevel !== 0 && (
          <div className="founder-dashboard-add-event__container d-md-none">
            <button
              onClick={this.openTimelineBuilder}
              className="btn btn-md btn-secondary text-uppercase founder-dashboard-add-event__btn js-founder-dashboard__trigger-builder"
            >
              <i className="fa fa-plus" aria-hidden="true" />
              <span className="sr-only">Add Timeline Event</span>
            </button>
          </div>
        )}
      </div>
    );
  }
}

ToggleBar.propTypes = {
  availableTrackIds: PropTypes.array.isRequired,
  rootProps: PropTypes.object.isRequired,
  rootState: PropTypes.object.isRequired,
  setRootState: PropTypes.func.isRequired
};
