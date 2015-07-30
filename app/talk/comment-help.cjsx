React = require 'react'

module?.exports = React.createClass
  displayName: 'TalkCommentHelp'

  render: ->
    <div className="talk-comment-help">
      <h1>Guide to commenting on talk</h1>
      <p>Talk comments are written in <a href='http://daringfireball.net/projects/markdown/basics'>markdown</a></p>
      <p>Mention users with <em>@username</em></p>
      <p>Mention subjects with <em>@owner/project^subject_id</em> or with <em>^subject_id</em>if you are inside of the subject's talk</p>
      <p>Create hashtags with <em>#hashtag</em></p>
    </div>
