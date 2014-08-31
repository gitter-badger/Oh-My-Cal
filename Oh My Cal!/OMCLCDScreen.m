///:
/*****************************************************************************
 **                                                                         **
 **                               .======.                                  **
 **                               | INRI |                                  **
 **                               |      |                                  **
 **                               |      |                                  **
 **                      .========'      '========.                         **
 **                      |   _      xxxx      _   |                         **
 **                      |  /_;-.__ / _\  _.-;_\  |                         **
 **                      |     `-._`'`_/'`.-'     |                         **
 **                      '========.`\   /`========'                         **
 **                               | |  / |                                  **
 **                               |/-.(  |                                  **
 **                               |\_._\ |                                  **
 **                               | \ \`;|                                  **
 **                               |  > |/|                                  **
 **                               | / // |                                  **
 **                               | |//  |                                  **
 **                               | \(\  |                                  **
 **                               |  ``  |                                  **
 **                               |      |                                  **
 **                               |      |                                  **
 **                               |      |                                  **
 **                               |      |                                  **
 **                   \\    _  _\\| \//  |//_   _ \// _                     **
 **                  ^ `^`^ ^`` `^ ^` ``^^`  `^^` `^ `^                     **
 **                                                                         **
 **                       Copyright (c) 2014 Tong G.                        **
 **                          ALL RIGHTS RESERVED.                           **
 **                                                                         **
 ****************************************************************************/

#import "OMCLCDScreen.h"
#import "OMCOperand.h"
#import "OMCCalculation.h"

NSInteger static const kSpaceBarsCount = 4;

// OMCLCDScreen class
@implementation OMCLCDScreen
    {
    NSRect _LCDBoundary;
    NSRect _gridPathBoundary;
    }

@synthesize _calculation;

@synthesize auxiliaryLinePath = _auxiliaryLinePath;
@synthesize gridPath = _gridPath;

@synthesize bottommostSpaceBar = _bottommostSpaceBar;
@synthesize secondSpaceBar = _secondSpaceBar;
@synthesize thirdSpaceBar = _thirdSpaceBar;
@synthesize topmostSpaceBar = _topmostSpaceBar;

@synthesize gridColor = _gridColor;
@synthesize auxiliaryLineColor = _auxiliaryLineColor;
@synthesize operandsColor = _operandsColor;
@synthesize operatorsColor = _operatorsColor;
@synthesize storageFormulasColor = _storageFormulasColor;

@synthesize operandsFont = _operandsFont;
@synthesize operatorsFont = _operatorsFont;
@synthesize storageFormulasFont = _storageFormulasFont;

@synthesize typingState = _typingState;
@synthesize currentAry = _currentAry;

- ( BOOL ) canBecomeKeyView
    {
    return YES;
    }

#pragma mark Initializers & Deallocators
- ( void ) awakeFromNib
    {
    self.gridColor = [ [ NSColor lightGrayColor ] colorWithAlphaComponent: .3 ];
    self.auxiliaryLineColor = [ NSColor colorWithDeviceRed: .3373f green: .3373f blue: .3412f alpha: 1.f ];
    self.operandsColor = [ NSColor whiteColor ];
    self.operatorsColor = self.operandsColor;
    self.storageFormulasColor = [ NSColor whiteColor ];

    self.operandsFont = [ NSFont fontWithName: @"PT Mono" size: 15 ];
    self.operatorsFont = [ [ NSFontManager sharedFontManager ] convertFont: self.operandsFont toSize: 13 ];
    self.storageFormulasFont = self.operandsFont;

    [ self setTypingState: OMCWaitAllOperands ];
    [ self setCurrentAry: ( OMCAry )[ USER_DEFAULTS objectForKey: OMCDefaultsKeyAry ] ];

    [ NOTIFICATION_CENTER addObserver: self
                             selector: @selector( currentTypingStateDidChanged: )
                                 name: OMCCurrentTypingStateDidChangedNotification
                               object: self._calculation ];

    [ NOTIFICATION_CENTER addObserver: self
                             selector: @selector( currentTypingStateDidChanged: )
                                 name: OMCCurrentAryDidChangedNotification
                               object: self._calculation ];
    }

- ( void ) currentTypingStateDidChanged: ( NSNotification* )_Notif
    {
    [ self setNeedsDisplay: YES ];
    }

- ( void ) viewWillMoveToWindow: ( NSWindow* )_Window
    {
    _LCDBoundary = [ self bounds ];

    // Line Path
    [ self _initializeLinePath ];
    }

- ( void ) _initializeOperandSpaceBars
    {
    [ self _initializeGridPath ];

    CGFloat spaceBarX = NSMinX( _gridPathBoundary );
    CGFloat spaceBarWidth = NSWidth( _gridPathBoundary );
    CGFloat spaceBarHeight = NSHeight( _gridPathBoundary ) / kSpaceBarsCount;

    self->_bottommostSpaceBar = NSMakeRect( spaceBarX
                                          , NSMinY( _gridPathBoundary )
                                          , spaceBarWidth
                                          , spaceBarHeight
                                          );

    self->_secondSpaceBar = NSMakeRect( spaceBarX
                                      , NSMaxY( self->_bottommostSpaceBar )
                                      , spaceBarWidth
                                      , spaceBarHeight
                                      );

    self->_thirdSpaceBar = NSMakeRect( spaceBarX
                                     , NSMaxY( self->_secondSpaceBar )
                                     , spaceBarWidth
                                     , spaceBarHeight
                                     );

    self->_topmostSpaceBar = NSMakeRect( spaceBarX
                                       , NSMaxY( self->_thirdSpaceBar )
                                       , spaceBarWidth
                                       , spaceBarHeight
                                       );
    }

- ( void ) _initializeLinePath
    {
    if ( !self.auxiliaryLinePath )
        {
        [ self _initializeOperandSpaceBars ];

        self.auxiliaryLinePath = [ NSBezierPath bezierPath ];
        [ self.auxiliaryLinePath moveToPoint: NSMakePoint( NSMinX( self.bottommostSpaceBar ), NSMaxY( self.bottommostSpaceBar ) ) ];
        [ self.auxiliaryLinePath lineToPoint: NSMakePoint( NSMaxX( self.bottommostSpaceBar ), NSMaxY( self.bottommostSpaceBar ) ) ];
        [ self.auxiliaryLinePath setLineWidth: 2 ];
        }
    }

- ( void ) _initializeGridPath
    {
    if ( !self.gridPath )
        {
        NSRect gridPathBounds = NSInsetRect( self.bounds, 10, 10 );
        gridPathBounds.size.height -= 26.5;

        NSAffineTransform* affine = [ NSAffineTransform transform ];
        [ affine translateXBy: 0.f yBy: 26.5 ];
        gridPathBounds.origin = [ affine transformPoint: gridPathBounds.origin ];

        _gridPathBoundary = gridPathBounds;

        self.gridPath = [ NSBezierPath bezierPathWithRect: gridPathBounds ];

        CGFloat height = gridPathBounds.size.height;
        CGFloat horizontalGridSpacing = height / kSpaceBarsCount;

        for ( int hor = 1; hor < height / horizontalGridSpacing; hor++ )
            {
            [ self.gridPath moveToPoint: NSMakePoint( NSMinX( gridPathBounds ), NSMinY( gridPathBounds ) + hor * horizontalGridSpacing ) ];
            [ self.gridPath lineToPoint: NSMakePoint( NSMaxX( gridPathBounds ), NSMinY( gridPathBounds ) + hor * horizontalGridSpacing ) ];
            }

        CGFloat dashes[ 2 ];
        dashes[ 0 ] = 1;
        dashes[ 1 ] = 2;
        [ self.gridPath setLineDash: dashes count: 2 phase: .0f ];
        }
    }

#pragma mark Customize Drawing
- ( void ) _drawTheAuxiliaryLine
    {
    [ NSGraphicsContext saveGraphicsState ];
        [ self.auxiliaryLineColor set ];
        [ self.auxiliaryLinePath stroke ];
    [ NSGraphicsContext restoreGraphicsState ];
    }

- ( void ) _drawLhsOperandWithAttributes: ( NSDictionary* )_Attributes
    {
    /* When the user is typing left operand... */

    OMCOperand* operand = self._calculation.lhsOperand;
    OMCAry currentAry = self._calculation.currentAry;
    NSString* lhsOperandInString = nil;

    if ( currentAry == OMCOctal )
        lhsOperandInString = [ operand inOctal ];
    else if ( currentAry == OMCDecimal )
        lhsOperandInString = [ operand inDecimal ];
    else if ( currentAry == OMCHex )
        lhsOperandInString = [ operand inHex ];

    /* ...we should only draw the left operand into the bottommost space bar. It's easy, isn't it? :) */
    [ lhsOperandInString drawAtPoint: [ self _pointUsedForDrawingOperands: lhsOperandInString inSpaceBar: self.bottommostSpaceBar ]
                      withAttributes: _Attributes ];
    }

- ( void ) _drawRhsOperandWithAttributesForOperands: ( NSDictionary* )_AttributesForOperands
                                     andForOperator: ( NSDictionary* )_AttributesForOperator
    {
    /* When the user is typing right operand... */

    OMCOperand* lhsOperand = self._calculation.lhsOperand;
    OMCOperand* rhsOperand = self._calculation.rhsOperand;

    OMCAry currentAry = self._calculation.currentAry;

    NSString* lhsOperandInString = nil;
    NSString* rhsOperandInString = nil;

    if ( currentAry == OMCOctal )
        {
        lhsOperandInString = [ lhsOperand inOctal ];
        rhsOperandInString = [ rhsOperand inOctal ];
        }
    else if ( currentAry == OMCDecimal )
        {
        lhsOperandInString = [ lhsOperand inDecimal ];
        rhsOperandInString = [ rhsOperand inDecimal ];
        }
    else if ( currentAry == OMCHex )
        {
        lhsOperandInString = [ lhsOperand inHex ];
        rhsOperandInString = [ rhsOperand inHex ];
        }

    /* ...we must draw a left operand into the bottom third space bar... */
    [ lhsOperandInString drawAtPoint: [ self _pointUsedForDrawingOperands: lhsOperandInString inSpaceBar: self.thirdSpaceBar ]
                      withAttributes: _AttributesForOperands ];

    /* ...draw the right operand the user is typing into the bottom second space bar... */
    [ rhsOperandInString drawAtPoint: [ self _pointUsedForDrawingOperands: rhsOperandInString inSpaceBar: self.secondSpaceBar ]
                      withAttributes: _AttributesForOperands ];

    /* ...draw the operator the user selected into the bottom second space bar... */
    [ self._calculation.theOperator drawAtPoint: [ self _pointUsedForDrawingOperators: self._calculation.theOperator ]
                                 withAttributes: _AttributesForOperator ];

    /* ...and draw a auxiliary line! */
    [ self _drawTheAuxiliaryLine ];

    /* But wait! You might want to ask: where is the result value? Aha! */
    }

- ( void ) _drawResultValWithAttributesForOperands: ( NSDictionary* )_AttributesForOperands
                                    andForOperator: ( NSDictionary* )_AttributesForOperator
    {
    OMCOperand* resultValue = self._calculation.resultValue;
    OMCAry currentAry = self._calculation.currentAry;

    NSString* resultValueInString = nil;

    if ( currentAry == OMCOctal )
        resultValueInString = [ resultValue inOctal ];
    else if ( currentAry == OMCDecimal )
        resultValueInString = [ resultValue inDecimal ];
    else if ( currentAry == OMCHex )
        resultValueInString = [ resultValue inHex ];

    [ resultValueInString drawAtPoint: [ self _pointUsedForDrawingOperands: resultValueInString inSpaceBar: self.bottommostSpaceBar ]
                       withAttributes: _AttributesForOperands ];

    if ( self._calculation.lastTypedButtonType != OMCFactorial
            && self._calculation.lastTypedButtonType != OMCNor
            && self._calculation.lastTypedButtonType != OMCRoL )
        [ self _drawRhsOperandWithAttributesForOperands: _AttributesForOperands
                                         andForOperator: _AttributesForOperator ];
    }

/* Initial state of Oh My Cal!: 1. Left Operand is empty
 *                              2. Right Operand is empty
 *                              3. Operator is empty
 *                              4. Result Val is empty
 */
- ( void ) _drawPlaceholderForTypingState: ( OMCTypingState )_CurrentTypingState
                           withAttributes: ( NSDictionary* )_Attributes
    {
    NSString* placeholder = nil;
    OMCAry currentAry = self._calculation.currentAry;

    if ( currentAry == OMCOctal || currentAry == OMCDecimal )
        placeholder = @"0";
    else if ( currentAry == OMCHex )
        placeholder = @"0x0";

     /* If Oh My Cal! is in the initial state or user has already typed *nothing* for current operand
      * draw a "0" for Octal and Decimal and a "0x0" for Hex, respectively. */
    if ( _CurrentTypingState == OMCWaitAllOperands
        /* If the length of lhsOperand is greater than 0, that means no need to draw the placeholder for left operand */
        && self._calculation.lhsOperand.isZero )
        {
        // As with all calculators, the initial state should only be drawn in the bottommost space bar.
        [ placeholder drawAtPoint: [ self _pointUsedForDrawingOperands: placeholder inSpaceBar: self.bottommostSpaceBar ]
                   withAttributes: _Attributes ];
        }
    else if ( _CurrentTypingState == OMCWaitRhsOperand
        /* If the length of rhsOperand is greater than 0, that means no need to draw the placeholder for right operand */
        && self._calculation.rhsOperand.isZero )
        {
        [ placeholder drawAtPoint: [ self _pointUsedForDrawingOperands: placeholder inSpaceBar: self.secondSpaceBar ]
                   withAttributes: _Attributes ];
        }
    }

- ( void ) drawRect: ( NSRect )_DirtyRect
    {
    [ super drawRect: _DirtyRect ];

    [ self.gridColor set ];
    [ self.gridPath stroke ];

    NSDictionary* drawingAttributesForOperands = @{ NSFontAttributeName : self.operandsFont
                                                  , NSForegroundColorAttributeName : self.operandsColor
                                                  };

    NSDictionary* drawingAttributesForOperators = @{ NSFontAttributeName : self.operatorsFont
                                                   , NSForegroundColorAttributeName : self.operatorsColor
                                                   };

    [ self _drawPlaceholderForTypingState: self._calculation.typingState
                           withAttributes: drawingAttributesForOperands ];

    switch ( self._calculation.typingState )
        {
    case OMCWaitAllOperands:
            {
            // User has not typed the right operand, he is just typing the left operand.
            [ self _drawLhsOperandWithAttributes: drawingAttributesForOperands ];
            } break;

    case OMCWaitRhsOperand:
            {
            [ self _drawRhsOperandWithAttributesForOperands: drawingAttributesForOperands
                                             andForOperator: drawingAttributesForOperators ];
            } break;

    case OMCFinishedTyping:
            {
            [ self _drawResultValWithAttributesForOperands: drawingAttributesForOperands
                                            andForOperator: drawingAttributesForOperators ];
            } break;
        }
    }

- ( NSPoint ) _pointUsedForDrawingOperators: ( NSString* )_Operator
    {
    NSPoint pointUsedForDrawing = NSZeroPoint;

    if ( _Operator && _Operator.length > 0 )
        {
        NSSize size = [ _Operator sizeWithAttributes: @{ NSFontAttributeName : self.operatorsFont } ];

        CGFloat paddingForAesthetic = 5.f;
        pointUsedForDrawing.x = NSMinX( self->_secondSpaceBar ) + paddingForAesthetic;
        pointUsedForDrawing.y = NSMinY( self->_secondSpaceBar ) + ( NSHeight( self->_secondSpaceBar ) - size.height ) / 2;
        }

    return pointUsedForDrawing;
    }

- ( NSPoint ) _pointUsedForDrawingOperands: ( NSString* )_Operand
                                inSpaceBar: ( OMCSpaceBarRect )_SpaceBarRect
    {
    NSPoint pointUsedForDrawing = NSZeroPoint;

    if ( _Operand && _Operand.length > 0 )
        {
        NSSize size = [ _Operand sizeWithAttributes: @{ NSFontAttributeName : self.operandsFont } ];

        CGFloat paddingForAesthetic = 5.f;
        pointUsedForDrawing.x = NSMaxX( _SpaceBarRect ) - size.width - paddingForAesthetic;

        // Centered Vertically
        pointUsedForDrawing.y = NSMinY( _SpaceBarRect ) + ( NSHeight( _SpaceBarRect ) - size.height ) / 2;
        }

    return pointUsedForDrawing;
    }

@end // OMCLCDScreen class

//////////////////////////////////////////////////////////////////////////////

/*****************************************************************************
 **                                                                         **
 **      _________                                      _______             **
 **     |___   ___|                                   / ______ \            **
 **         | |     _______   _______   _______      | /      |_|           **
 **         | |    ||     || ||     || ||     ||     | |    _ __            **
 **         | |    ||     || ||     || ||     ||     | |   |__  \           **
 **         | |    ||     || ||     || ||     ||     | \_ _ __| |  _        **
 **         |_|    ||_____|| ||     || ||_____||      \________/  |_|       **
 **                                           ||                            **
 **                                    ||_____||                            **
 **                                                                         **
 ****************************************************************************/
///:~