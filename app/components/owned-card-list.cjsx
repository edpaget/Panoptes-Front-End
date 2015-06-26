counterpart = require 'counterpart'
React = require 'react'
TitleMixin = require '../lib/title-mixin'
Translate = require 'react-translate-component'
apiClient = require '../api/client'
PromiseRenderer = require '../components/promise-renderer'
OwnedCard = require '../partials/owned-card'
{Link} = require 'react-router'
Waypoint = require 'react-waypoint'
PromiseToSetState = require '../lib/promise-to-set-state'
uniq = require 'lodash.uniq'

module.exports = React.createClass
  displayName: 'OwnedCardList'

  mixins: [PromiseToSetState]

  propTypes:
    imagePromise: React.PropTypes.func.isRequired
    pagedResource: React.PropTypes.object.isRequired
    cardLink: React.PropTypes.func.isRequired
    translationObjectName: React.PropTypes.string.isRequired
    ownerName: React.PropTypes.string
    heroClass: React.PropTypes.string
    heroNav: React.PropTypes.node

  componentDidMount: ->
    document.documentElement.classList.add 'on-secondary-page'
    @fetchResources()

  componentWillUnmount: ->
    document.documentElement.classList.remove 'on-secondary-page'

  userForTitle: ->
    if @props.ownerName
      "#{@props.ownerName}'s"
    else
      'All'

  getInitialState: ->
    ownedResources: []

  fetchResources: ->
    unless @state.pending.ownedResources?
      ownedResources = @props.pagedResource.getNextPage().then (resources) =>
        console.log(resources)
        uniq(@state.ownedResources.concat(resources), (p) -> p.id)
      @promiseToSetState {ownedResources} 

  renderCards: ->
    for resource in @state.ownedResources
      <OwnedCard
        key={"project-#{resource.id}"}
        resource={resource}
        imagePromise={@props.imagePromise(resource)}
        linkTo={@props.cardLink(resource)}
        translationObjectName={@props.translationObjectName}/>
 
  render: ->
    <div className="secondary-page all-resources-page">
      <section className={"hero #{@props.heroClass}"}>
        <div className="hero-container">
          <Translate component="h1" user={@userForTitle()} content={"#{@props.translationObjectName}.title"} />
          {if @props.heroNav?
            @props.heroNav}
        </div>
      </section>
      <section className="resources-container">
        <div>
          {if @state.ownedResources?.length > 0
             <div className="card-list">
               {@renderCards()}
               <Waypoint onEnter={@fetchResources} threshold={0.1}} />
             </div>
           else if @state.pending.ownedResources?
             <Translate content="#{@props.translationObjectName}.loadMessage" component="div" />
           else 
             <Translate content="#{@props.translationObjectName}.notFoundMessage" component="div" />}
        </div>
      </section>
    </div>
