import React from "react";
import PropTypes from "prop-types";
import NonCoderFailed from "./NonCoderFailed";
import CoderFailed from "./CoderFailed";
import NonCoderPassed from "./NonCoderPassed";
import CoderPassed from "./CoderPassed";

export default class QuizResult extends React.Component {
  buttonClasses() {
    let classes = "btn btn-with-icon btn-md text-uppercase";

    if (this.props.passed) {
      classes += " btn-primary";
    } else {
      classes += " btn-secondary";
    }

    return classes;
  }

  buttonIconClasses() {
    let classes = "fa";

    if (this.props.passed) {
      classes += " fa-arrow-right";
    } else {
      classes += " fa-refresh";
    }

    return classes;
  }

  heading() {
    if (this.props.passed) {
      return { __html: "&#x1F389;&nbsp;Congratulations" };
    } else {
      return { __html: "&#x1F61F;&nbsp;Sorry" };
    }
  }

  render() {
    return (
      <div className="applicant-screening__quiz-result">
        <h3
          className="font-semibold brand-primary mb-3"
          dangerouslySetInnerHTML={this.heading()}
        />

        {this.props.passed && this.props.type === "coder" && <CoderPassed />}

        {this.props.passed &&
          this.props.type === "non-coder" && <NonCoderPassed />}

        {!this.props.passed && this.props.type === "coder" && <CoderFailed />}

        {!this.props.passed &&
          this.props.type === "non-coder" && <NonCoderFailed />}

        {this.props.passed && (
          <form acceptCharset="UTF-8" method="post">
            <input name="utf8" type="hidden" value="✓" />
            <input
              type="hidden"
              name="authenticity_token"
              value={this.props.formAuthenticityToken}
            />
            <input type="hidden" name="founder_skill" value={this.props.type} />
            <input
              type="hidden"
              name="github_url"
              value={this.props.githubURL}
            />

            <button type="submit" className={this.buttonClasses()}>
              <i className={this.buttonIconClasses()} /> Continue
            </button>
          </form>
        )}

        {!this.props.passed && (
          <button className={this.buttonClasses()} onClick={this.props.resetCB}>
            <i className={this.buttonIconClasses()} /> Restart
          </button>
        )}
      </div>
    );
  }
}

QuizResult.propTypes = {
  passed: PropTypes.bool,
  resetCB: PropTypes.func,
  type: PropTypes.string,
  formAuthenticityToken: PropTypes.string,
  githubURL: PropTypes.string
};
