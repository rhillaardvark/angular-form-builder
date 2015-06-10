# ----------------------------------------
# Shared functions
# ----------------------------------------
copyObjectToScope = (object, scope) ->
    ###
    Copy object (ng-repeat="object in objects") to scope without `hashKey`.
    ###
    for key, value of object when key isnt '$$hashKey'
        # copy object.{} to scope.{}
        scope[key] = value
    return


# ----------------------------------------
# builder.controller
# ----------------------------------------
angular.module 'builder.controller', ['builder.provider']

# ----------------------------------------
# fbFormObjectEditableController
# ----------------------------------------
.controller 'fbFormObjectEditableController', ['$scope', '$injector', ($scope, $injector) ->
    $builder = $injector.get '$builder'

    $scope.setupScope = (formObject) ->
        ###
        1. Copy origin formObject (ng-repeat="object in formObjects") to scope.
        2. Setup optionsText with formObject.options.
        3. Watch scope.label, .description, .placeholder, .required, .options then copy to origin formObject.
        4. Watch scope.optionsText then convert to scope.options.
        5. setup validationOptions
        ###
        copyObjectToScope formObject, $scope

        $scope.optionsText = formObject.options.join '\n'

        $scope.$watch '[' + $builder.watchItems.toString() + ']', ->
            ((formObject[watchedField] = $scope[watchedField]) for watchedField in $builder.watchItems)
        , yes

        $scope.$watch 'optionsText', (text) ->
            $scope.options = (x for x in text.split('\n') when x.length > 0)
            $scope.inputText = $scope.options[0]

        component = $builder.components[formObject.component]
        $scope.validationOptions = component.validationOptions

    $scope.data =
        model: null
        backup: ->
            ###
            Backup input value.
            ###
            @model = {}
            ((@model[watchedField] = $scope[watchedField]) for watchedField in $builder.watchItems)
        rollback: ->
            ###
            Rollback input value.
            ###
            return if not @model
            (($scope[watchedField] = @model[watchedField]) for watchedField in $builder.watchItems)
]


# ----------------------------------------
# fbComponentsController
# ----------------------------------------
.controller 'fbComponentsController', ['$scope', '$injector', ($scope, $injector) ->
    # providers
    $builder = $injector.get '$builder'

    # action
    $scope.selectGroup = ($event, group) ->
        $event?.preventDefault()
        $scope.activeGroup = group
        $scope.components = []
        for name, component of $builder.components when component.group is group
            $scope.components.push component

    $scope.groups = $builder.groups
    $scope.activeGroup = $scope.groups[0]
    $scope.allComponents = $builder.components
    $scope.$watch 'allComponents', -> $scope.selectGroup null, $scope.activeGroup
]


# ----------------------------------------
# fbComponentController
# ----------------------------------------
.controller 'fbComponentController', ['$scope', ($scope) ->
    $scope.copyObjectToScope = (object) -> copyObjectToScope object, $scope
]


# ----------------------------------------
# fbFormController
# ----------------------------------------
.controller 'fbFormController', ['$scope', '$injector', ($scope, $injector) ->
    # providers
    $builder = $injector.get '$builder'
    $timeout = $injector.get '$timeout'

    # set default for input
    $scope.input ?= []
    $scope.$watch 'form', ->
        # remove superfluous input
        if $scope.input.length > $scope.form.length
            $scope.input.splice $scope.form.length
        # tell children to update input value.
        # ! use $timeout for waiting $scope updated.
        $timeout ->
            $scope.$broadcast $builder.broadcastChannel.updateInput
    , yes
]


# ----------------------------------------
# fbFormObjectController
# ----------------------------------------
.controller 'fbFormObjectController', ['$scope', '$injector', ($scope, $injector) ->
    # providers
    $builder = $injector.get '$builder'

    $scope.copyObjectToScope = (object) -> copyObjectToScope object, $scope

    $scope.updateInput = (value) ->
        ###
        Copy current scope.input[X] to $parent.input.
        @param value: The input value.
        ###
        input =
            id: $scope.formObject.id
            label: $scope.formObject.label
            value: value ? ''
        $scope.$parent.input.splice $scope.$index, 1, input
]
