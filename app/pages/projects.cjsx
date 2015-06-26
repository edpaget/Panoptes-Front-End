counterpart = require 'counterpart'
React = require 'react'
TitleMixin = require '../lib/title-mixin'
apiClient = require '../api/client'
OwnedCardList = require '../components/owned-card-list'
PagedResource = require '../lib/paged-resource'

counterpart.registerTranslations 'en',
  projectsPage:
    title: 'All Projects'
    countMessage: 'Showing %(pageStart)s-%(pageEnd)s of %(count)s found'
    button: 'Get Started'
    notFoundMessage: 'Sorry, no projects found'

module.exports = React.createClass
  displayName: 'ProjectsPage'

  mixins: [TitleMixin]

  title: 'Projects'

  projects: ->
    query =
      launch_approved: true
      include:'owners,avatar'

    new PagedResource('projects', 1, query)

  imagePromise: (project) ->
    project.get('avatar')
      .then (avatar) -> avatar.src

  cardLink: (project) ->
    link = if !!project.redirect
      project.redirect
    else
      'project-home'

    return link

  render: ->
    <OwnedCardList
      translationObjectName="projectsPage"
      pagedResource={@projects()}
      linkTo="projects"
      cardLink={@cardLink}
      heroClass="projects-hero"
      imagePromise={@imagePromise} />
