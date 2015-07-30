React = require 'react'
Router = require 'react-router'
intersection = require 'lodash.intersection'
pick = require 'lodash.pick'
Translate = require 'react-translate-component'
counterpart = require 'counterpart'
apiClient = require '../api/client'
Paginator = require '../talk/lib/paginator'
PromiseRenderer = require '../components/promise-renderer'
SubjectViewer = require '../components/subject-viewer'
Loading = require '../components/loading-indicator'
{Link} = require 'react-router'

VALID_COLLECTION_MEMBER_SUBJECTS_PARAMS = ['page', 'page_size']

counterpart.registerTranslations 'en',
  collectionSubjectListPage:
    error: 'There was an error listing this collection.'
    noSubjects: 'No subjects in this collection.'

module?.exports = React.createClass
  displayName: 'CollectionShowList'
  mixins: [Router.Navigation, Router.State]

  componentDidMount: ->
    @fetchCollectionSubjects pick @props.query, VALID_COLLECTION_MEMBER_SUBJECTS_PARAMS

  componentWillReceiveProps: (nextProps) ->
    @fetchCollectionSubjects pick nextProps.query, VALID_COLLECTION_MEMBER_SUBJECTS_PARAMS

  fetchCollectionSubjects: (query = null) ->
    query ?= @props.query

    defaultQuery =
      page: 1
      page_size: 12

    query = Object.assign defaultQuery, query
    return @props.collection.get 'subjects', query

  onPageChange: (page) ->
    nextQuery = Object.assign @props.query, { page }
    @transitionTo @getPath(), @props.params, nextQuery

  handleDeleteSubject: (subject) ->
    @props.collection.removeLink 'subjects', [subject.id.toString()]
      .then =>
        @props.collection.uncacheLink 'subjects'
        @forceUpdate()

  isOwnerOrCollaborator: ->
    collaboratorOrOwnerRoles = @props.roles.filter (collectionRoles) ->
      intersection(['owner', 'collaborator'], collectionRoles.roles).length

    hasPermission = false
    collaboratorOrOwnerRoles.forEach (roleSet) =>
      if roleSet.links.owner.id is @props.user?.id
        hasPermission = true

    return hasPermission

  fetchProjectOwner: (subject) ->
    projectRequest = if @props.collection.links.project?
      @props.collection.get('project')
    else
      subject.get('project')

    projectRequest.then (project) ->
      [owner, name] = project.slug.split('/')
      {owner: owner, name: name, id: subject.id}

  render: ->
    subjectNode = (subject) =>
      <div className="collection-subject-viewer" key={subject.id}>
        <SubjectViewer defaultStyle={false} subject={subject} user={@props.user}>
          {if @isOwnerOrCollaborator()
            <button type="button" className="collection-subject-viewer-delete-button" onClick={@handleDeleteSubject.bind @, subject}>
              <i className="fa fa-close" />
            </button>}
          <PromiseRenderer promise={@fetchProjectOwner(subject)}>{ (params) =>
            <Link className="subject-link" to="project-talk-subject" params={params}>
              <span></span>
            </Link>
          }</PromiseRenderer>
        </SubjectViewer>
      </div>

    pendingFunc = ->
      <Loading />

    catchFunc = (e) ->
      <Translate component="p" className="form-help error" content="collectionSubjectListPage.error" />

    thenFunc = (subjects) =>
      <div className="collections-show">
        {if subjects.length is 0
          <Translate component="p" content="collectionSubjectListPage.noSubjects" />}

        {if subjects.length > 0
          <div>
            <div className="collection-subjects-list">{subjects.map(subjectNode)}</div>

            <Paginator
              page={+@props.query.page}
              onPageChange={@onPageChange}
              pageCount={subjects[0].getMeta().page_count} />
          </div>}
      </div>

    <PromiseRenderer
      promise={@fetchCollectionSubjects()}
      pending={pendingFunc}
      catch={catchFunc}
      then={thenFunc} />
