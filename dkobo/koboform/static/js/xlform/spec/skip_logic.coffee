describe 'skip logic model', () ->
  describe 'skip logic factory', () ->
    _factory = new XLF.Model.SkipLogicFactory()

    beforeEach ->
      @addMatchers toBeInstanceOf: (expectedInstance) ->
        actual = @actual
        notText = (if @isNot then " not" else "")
        @message = ->
          "Expected " + actual.constructor.name + notText + " is instance of " + expectedInstance.name

        actual instanceof expectedInstance

      return


    it 'creates a basic skip logic operator', () ->
      operator = _factory.create_operator 'basic', '=', 1

      expect(operator).toBeInstanceOf XLF.SkipLogicOperator
      expect(operator.get('id')).toBe 1
      expect(operator.get('symbol')).toBe '='

    it 'creates a text skip logic operator', () ->
      operator = _factory.create_operator 'text', '=', 1

      expect(operator).toBeInstanceOf XLF.TextOperator
      expect(operator.get('id')).toBe 1
      expect(operator.get('symbol')).toBe '='

    it 'creates an existence skip logic operator', () ->
      operator = _factory.create_operator 'existence', '=', 1

      expect(operator).toBeInstanceOf XLF.ExistenceSkipLogicOperator
      expect(operator.get('id')).toBe 1
      expect(operator.get('symbol')).toBe '='

    it 'creates a select multiple skip logic operator', () ->
      operator = _factory.create_operator 'select_multiple', '=', 1

      expect(operator).toBeInstanceOf XLF.SelectMultipleSkipLogicOperator
      expect(operator.get('id')).toBe 1
      expect(operator.get('symbol')).toBe '='

    it 'creates an empty skip logic operator', () ->
      operator = _factory.create_operator 'empty', '=', 1

      expect(operator).toBeInstanceOf XLF.EmptyOperator
      expect(operator.get('id')).toBe 0
      expect(operator.get('symbol')).toBeUndefined()

    it 'creates a criterion model', () ->
      criterion = _factory.create_criterion_model 'test question', 'test operator'

      expect(criterion).toBeInstanceOf XLF.SkipLogicCriterion

    it 'creates a text response model', () ->
      expect(_factory.create_response_model 'text').toBeInstanceOf XLF.Model.TextResponseModel

    it 'creates an integer response model', () ->
      expect(_factory.create_response_model 'integer').toBeInstanceOf XLF.Model.IntegerResponseModel

    it 'creates a decimal response model', () ->
      expect(_factory.create_response_model 'decimal').toBeInstanceOf XLF.Model.DecimalResponseModel
  describe 'skip logic criterion', () ->
    _criterion = null
    _operator = null

    beforeEach () ->
      _criterion = new XLF.SkipLogicCriterion
      _operator =
        serialize: sinon.stub().withArgs('test question', 'test value').returns 'test criterion'

      _criterion.set 'question_name', 'test question'
      _criterion.set 'operator', _operator

    it 'serializes the criterion when response model validation state is true', () ->
      response_model =
        isValid: () -> true
        get: () -> 'test value'

      _criterion.set 'response_value', response_model

      expect(_criterion.serialize()).toBe 'test criterion'
    it 'serializes the criterion when response model validation state is undefined', () ->
      response_model =
        isValid: () -> undefined
        get: () -> 'test value'

      _criterion.set 'response_value', response_model

      expect(_criterion.serialize()).toBe 'test criterion'
    it 'serializes to empty value when response model validation state is false', () ->
      response_model =
        isValid: () -> false

      _criterion.set 'response_value', response_model

      expect(_criterion.serialize()).toBe ''
    it 'changes the operator model', () ->
      _criterion.change_operator 'test operator'

      expect(_criterion.get 'operator').toBe 'test operator'
    it 'changes the question name', () ->
      _criterion.change_question 'test question'

      expect(_criterion.get 'question_name').toBe 'test question'
    it 'changes the response value', () ->
      response_model =
        set: sinon.spy()

      _criterion.set 'response_value', response_model
      _criterion.change_response 'test value'

      expect(_criterion.get('response_value').set).toHaveBeenCalledWith 'value', 'test value'

  describe 'operator', () ->
    _operator = null

    beforeEach () ->
      _operator = new XLF.Operator
      _operator.set 'id', 1
    it 'gets the operator id when operator is negated', () ->
      _operator.set 'is_negated', true

      expect(_operator.get_value()).toBe '-1'
    it 'gets the operator id when operator is not negated', () ->
      _operator.set 'is_negated', false

      expect(_operator.get_value()).toBe '1'

  describe 'empty operator', () ->
    it 'serializes to an empty string', () ->
      expect(new XLF.EmptyOperator().serialize()).toBe ''

  describe 'skip logic operator', () ->
    it 'serializes the criterion', () ->
      operator = new XLF.SkipLogicOperator '='
      expect(operator.serialize 'test question', 'test response').toBe('${test question} = test response')

    it 'constructs criterion', () ->
      operator = new XLF.SkipLogicOperator '='
      expect(operator.get('is_negated')).toBeFalsy()
    it 'constructs negated criterion', () ->
      operator = new XLF.SkipLogicOperator '!='
      expect(operator.get('is_negated')).toBeTruthy()

  describe 'text operator', () ->
    it 'serializes the criterion as text', () ->
      operator = new XLF.TextOperator '='
      expect(operator.serialize 'test question', 'test response').toBe("${test question} = 'test response'")

  describe 'existence skip logic operator', ->
    it 'serializes the criterion', () ->
      operator = new XLF.ExistenceSkipLogicOperator '='
      expect(operator.serialize 'test question', 'test response').toBe("${test question} = ''")

    it 'constructs criterion', () ->
      operator = new XLF.ExistenceSkipLogicOperator '!='
      expect(operator.get('is_negated')).toBeFalsy()
    it 'constructs negated criterion', () ->
      operator = new XLF.ExistenceSkipLogicOperator '='
      expect(operator.get('is_negated')).toBeTruthy()

  describe 'select multiple skip logic operator', () ->
    it 'serializes the criterion', () ->
      operator = new XLF.SelectMultipleSkipLogicOperator '='
      expect(operator.serialize 'test question', 'test response').toBe("selected(${test question}, 'test response')")

    it 'serializes negated criterion', () ->
      operator = new XLF.SelectMultipleSkipLogicOperator '!='
      expect(operator.serialize 'test question', 'test response').toEqual("not(selected(${test question}, 'test response'))")

  describe 'integer response model', () ->
    _response_model = new XLF.Model.IntegerResponseModel()
    it 'sets state to valid when passed value is integer', () ->
      _response_model.set('value', 123, validate:true)

      expect(_response_model.isValid()).toBeTruthy()
    it 'sets state to invalid when passed value is decimal', () ->
      _response_model.set('value', 123.1234, validate:true)

      expect(_response_model.isValid()).toBeFalsy()
    it 'sets state to invalid when passed value is text', () ->
      _response_model.set('value', 'asdf', validate:true)

      expect(_response_model.isValid()).toBeFalsy()

  describe 'decimal response model', () ->
    _response_model = new XLF.Model.DecimalResponseModel()
    it 'sets state to valid when passed value is integer', () ->
      _response_model.set('value', 123, validate:true)

      expect(_response_model.isValid()).toBeTruthy()
    it 'sets state to invalid when passed value is decimal', () ->
      _response_model.set('value', 123.1234, validate:true)

      expect(_response_model.isValid()).toBeTruthy()
    it 'sets state to invalid when passed value is text', () ->
      _response_model.set('value', 'asdf', validate:true)

      expect(_response_model.isValid()).toBeFalsy()