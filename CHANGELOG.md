### 29 August, 2016

#### Features

  - Our SixWays MOOC can now be previewed without supplying an email address - signing up is required to be eligible for the certificate. 

#### Bugfixes

  - Fixed some bugs that could have popped up when updating or deleting timeline events.
  - Fixed a bug which allowed cofounders to login and see application state as though they were the team lead.
  - Improved handling of cases where supplied email address cannot be reached.

### 22 August, 2016

#### Features

  - Our free MOOC, [SixWays](sixways) is live. Check it out!
  - Picking a university from our select boxes should now be easier since it returns out-of-order results.

#### Content

  - Clarify dates related to the application process on the apply page.

#### Bugfixes

  - Applicants are now informed if their email address could not be reached, when attempting to send sign-in email (instead of crashing and showing a failure message).

### 15 August, 2016

#### Content, UI

  - Stage 2 (coding and video challenge) of the application process for batch #3 is now live!
  - Added lots of new content to the home page.

#### Features

  - On demand, we've modified the registration process for our SixWays MOOC to allow students from outside India to participate.

#### Bugfixes

  - Reference dropdown options on the application form weren't visible on Chrome (Windows). This has been fixed.

### 8 August, 2016

#### Content, UI

  - Our homepage is undergoing updates - new content has been added, and more is coming this week.
  - The _Startups_ page is now ordered by most recent activity.

#### Performance

  - When picking university when signing up for our MOOC, or for the latest batch, we used to preload all of the universities. Now the select box searches for, and returns only a subset of matching universities. This speeds up operation on mobiles significantly.

#### Bugfixes

  - The _Record Feedback_ option for signed-in founders went kaput. It's up and running again.
  - Founders are now asked to sign-in if they try to join a connect request. Earlier, they were met with a 404 if they weren't signed-in already.
  - Changes to the application process meant that all of the earlier sign-in mails sent to applicants contained links which 404-ed. All of those have been redirected to the new apply page.

### 1 August, 2016

#### Features

  - The widget to contact us via Facebook, Twitter or Email has been replaced! We now have a live chat function instead, active all over the site (including this page), where you can have a chat with us without any interruption. It's pretty slick, check it out!

#### UI and UX

  - Application process to batch 3 has been given a bit of an overhaul. We've altered and improved the way information is delivered to applicants, and reduced the amount of data we require for them to get started. Brand new apply page design included!
  - The latest posts from our Instagram account are now featured on the homepage!

### 25 July, 2016

#### Features

  - We introduced a widget for traffic landing on the website to contact us easily. Folks can now reach us directly through Facebook's Messenger, tweet to us, or mail us for a quick response.

#### Bugfixes

  - We'd messed up when we redirected sv.co to www.sv.co (new canonical URL), which was failing on Apple's Safari browser. This has been fixed.

#### UI and UX

  - Sign in page for existing founders has been updated to new design language.
  - Fixed broken styling of announcement headers when using new design.
  - Popup videos on apply page were not being centered correctly, and were overflowing on low-res mobiles. They now fit correctly within the viewport.

### 18 July, 2016

#### Features

  - Login e-mails are now sent immediately instead of being deferred, resulting in improved delivery times.

#### Bugfixes

  - Fixed some bugs related to addition of co-founders on batch 3's application form.
  - Apply page videos were being hidden by the floating header element on mobile view. They're now on top!

### 12 July, 2016

#### Features

  - New applicants can now redo their application form as long as they haven't completed the payment step.

#### Content

  - Added a [tour](/tour) of SV.CO's programme.

### 4 July, 2016

#### Features, UI, Content

  - Applications for batch 3 are open! We've been working towards this for the last four weeks. We've released a brand new home page featuring graduates from our first batch, new videos and content on the apply page, and a four-stage application process.

### 20 June, 2016

#### UX and UI

  - There's been a slight modification in the faculty connect request process. Due to a recent change in Google Hangouts, the Hangouts URL can only be generated a little while before the meeting takes place. Emails sent to founders and faculty will now have a link to a new page, which will reveal the Hangouts URL when it is available.
  - When founder is logged in, an _Activity_ link is added to the navbar, pointing to the page listing latest activity from startups.

#### Content

  - Added information about host institute change to the transparency page.

### 13 June, 2016

#### UX and UI

  - Check out our new changelog page! B-) We've applied our styleguide here, and we'll slowly roll out this design language across the entire website.

#### Bugfixes

  - Signed-in sessions were not being shared between _[sv.co](https://sv.co)_ and _[www.sv.co](https://www.sv.co)_. We were serving bad cookies, so we've baked a new batch. Everyone has been signed out as a result; sorry about that.
  - Vocalist is now able to define terms that have a _hyphen_ in them.

### 6 June, 2016

#### Features

  - Vocalist responds to `changelog`, and fetches the latest entry from this changelog.
  - Vocalist includes a summary of latest deployed targets in the response to `state of SV` commands.

#### UX and UI

  - Minor tweaks to navigation links.
  - Removed the option to pause and resume flash notifications.

#### Bugfixes

  - Fixed an issue with displaying feedback on timeline events when the feedback body lacked line-breaks.

### 1 June, 2016

#### Features

  - A form has been added to gather feedback from signed-in founders, on all aspects of the program. It's accessible from the profile dropdown menu (top-right).

#### UX and UI

  - The first version of our unified design guideline is ready. We've been working on it for the last few weeks, and we'll slowly roll out updated design elements over the next couple of weeks - starting with the changelog!

#### Bugfixes

  - There was a report of a rendering error (via the new platform feedback feature!) related to the display of founder targets. That's been taken care of.

### 24 May, 2016

#### Features

  - Tracking improved timeline events for those that were marked as needing improvement.

#### UX and UI

  - Vocalist now ignores case when responding to commands.
  - Removed play and pause buttons on notifications.
  - Updated SV.CO's address; we've got new digs in Bengaluru!

### 17 May, 2016

#### Features

  - Vocalist now supplies definitions to common industry terms using the `define TERM` command.

#### Bugfixes

  - The button to download _Rubric_ for targets was broken during an unrelated change. This has been fixed, and tests have been added.

### 9 May, 2016

#### Features

  - _Review tests_ have been added to targets. This allows founders to take part in small survey-type questionnaires after going through slides and / or completing targets.

#### Content

  - Added more information related to SV.CO's mission in the _About_ section.
  - _Ola_ and _GOQii_ have been listed as partners in the _Talent_ section.

#### Bugfixes

  - URLs that point to `/resources/...` now redirect to the new `/library/...` path. This preserves old links.
  - Improved reliability of reminder notifications sent via vocalist to faculty and founders about imminent connect sessions. They had a tendency to get lost in transit.

### 2 May, 2016

#### Features

  - A _Graduation_ page has been created to showcase our graduation efforts & results.
  - Vocalist includes questions asked by founders in the reminder for faculty members about imminent connect session.

#### Performance

  - We've switched our CDN from Cloudfront to Cloudflare to take advantage of [CNAME flattening](https://sv.co/tvyfw). This lets us bypass the CDN on dynamic page requests for considerable speed-up. Also, Cloudflare is way cooler. B-)

#### Visual

  - Minor changes to site's header and footer, re-organizing links, and such.

#### Bugfixes

  - Vocalist no longer includes an empty _Links attached_ postfix when links aren't available on a timeline event notification.
  - After editing a timeline event and submitting changes, the form now clears instead of remaining in _edit mode_.

### 25 April, 2016

#### Features

  - Vocalist now responds to a bunch of commands that makes her fetch basic information about a batch, for use as intro during weekly _town hall_ meetings.
  - Founder registration flow has been reworked. On-boarding a team of founders is much more straight-forward; the team lead is asked to enter startup information right after user registration, and co-founders being automatically linked once that's done.

### 18 April, 2016

#### Features

  - Vocalist now responds to `targets?` command, responding with list of targets. She can also supply more information with `targets info [NUMBER]`

#### Performance

  - Sped up first load of the website by tweaking a setting on the visit logging library.

#### Bugfixes

  - Blank entries were being shown on Startups page's filter (Google Chrome, on Windows).
  - Vocalist will correctly notify everyone of multiple targets being deployed together to a batch.
  - Founders can no longer register with phone numbers already linked to others.
