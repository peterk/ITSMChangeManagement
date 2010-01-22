# --
# Kernel/System/ITSMChange/ITSMCondition/Object.pm - all condition object functions
# Copyright (C) 2003-2010 OTRS AG, http://otrs.com/
# --
# $Id: Object.pm,v 1.20 2010-01-22 12:42:20 bes Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::ITSMChange::ITSMCondition::Object;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = qw($Revision: 1.20 $) [1];

=head1 NAME

Kernel::System::ITSMChange::ITSMCondition::Object - condition object lib

=head1 SYNOPSIS

All functions for condition objects in ITSMChangeManagement.

=head1 PUBLIC INTERFACE

=over 4

=item ObjectAdd()

Add a new condition object.

    my $ConditionID = $ConditionObject->ObjectAdd(
        Name   => 'ObjectName',
        UserID => 1,
    );

=cut

sub ObjectAdd {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(Name UserID)) {
        if ( !$Param{$Argument} ) {
            $Self->{LogObject}->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );
            return;
        }
    }

    # make lookup with given name for checks
    my $ObjectID = $Self->ObjectLookup(
        Name => $Param{Name},
    );

    # check if object name already exists
    if ($ObjectID) {
        $Self->{LogObject}->Log(
            Priority => 'error',
            Message  => "Condition object ($Param{Name}) already exists!",
        );
        return;
    }

    # add new object name to database
    return if !$Self->{DBObject}->Do(
        SQL => 'INSERT INTO condition_object '
            . '(name) '
            . 'VALUES (?)',
        Bind => [ \$Param{Name} ],
    );

    # get id of created object
    $ObjectID = $Self->ObjectLookup(
        Name => $Param{Name},
    );

    # check if object could be added
    if ( !$ObjectID ) {
        $Self->{LogObject}->Log(
            Priority => 'error',
            Message  => "ObjectAdd() failed!",
        );
        return;
    }

    return $ObjectID;
}

=item ObjectUpdate()

Update a condition object.

    my $Success = $ConditionObject->ObjectUpdate(
        ObjectID => 1234,
        Name     => 'NewObjectName',
        UserID   => 1,
    );

=cut

sub ObjectUpdate {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(ObjectID Name UserID)) {
        if ( !$Param{$Argument} ) {
            $Self->{LogObject}->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );
            return;
        }
    }

    # get object data
    my $ObjectData = $Self->ObjectGet(
        ObjectID => $Param{ObjectID},
        UserID   => $Param{UserID},
    );

    # check object data
    if ( !$ObjectData ) {
        $Self->{LogObject}->Log(
            Priority => 'error',
            Message  => "ObjectUpdate of $Param{ObjectID} failed!",
        );
        return;
    }

    # update object in database
    return if !$Self->{DBObject}->Do(
        SQL => 'UPDATE condition_object '
            . 'SET name = ? '
            . 'WHERE id = ?',
        Bind => [
            \$Param{Name},
            \$Param{ObjectID},
        ],
    );

    return 1;
}

=item ObjectGet()

Get a condition object for a given object id.
Returns a hash reference of the object data.

    my $ConditionObjectRef = $ConditionObject->ObjectGet(
        ObjectID => 1234,
        UserID   => 1,
    );

The returned hash reference contains following elements:

    $ConditionObject{ObjectID}
    $ConditionObject{Name}

=cut

sub ObjectGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(ObjectID UserID)) {
        if ( !$Param{$Argument} ) {
            $Self->{LogObject}->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );
            return;
        }
    }

    # prepare SQL statement
    return if !$Self->{DBObject}->Prepare(
        SQL   => 'SELECT id, name FROM condition_object WHERE id = ?',
        Bind  => [ \$Param{ObjectID} ],
        Limit => 1,
    );

    # fetch the result
    my %ObjectData;
    while ( my @Row = $Self->{DBObject}->FetchrowArray() ) {
        $ObjectData{ObjectID} = $Row[0];
        $ObjectData{Name}     = $Row[1];
    }

    # check error
    if ( !%ObjectData ) {
        $Self->{LogObject}->Log(
            Priority => 'error',
            Message  => "ObjectID $Param{ObjectID} does not exist!",
        );
        return;
    }

    return \%ObjectData;
}

=item ObjectLookup()

This method does a lookup for a condition object. If an object
id is given, it returns the name of the object. If the name of the
object is given, the appropriate id is returned.

    my $ObjectName = $ConditionObject->ObjectLookup(
        ObjectID => 4321,
    );

    my $ObjectID = $ConditionObject->ObjectLookup(
        Name   => 'ObjectName',
    );

=cut

sub ObjectLookup {
    my ( $Self, %Param ) = @_;

    # check if both parameters are given
    if ( $Param{ObjectID} && $Param{Name} ) {
        $Self->{LogObject}->Log(
            Priority => 'error',
            Message  => 'Need ObjectID or Name - not both!',
        );
        return;
    }

    # check if both parameters are not given
    if ( !$Param{ObjectID} && !$Param{Name} ) {
        $Self->{LogObject}->Log(
            Priority => 'error',
            Message  => 'Need ObjectID or Name - none is given!',
        );
        return;
    }

    # prepare SQL statements
    if ( $Param{ObjectID} ) {
        return if !$Self->{DBObject}->Prepare(
            SQL   => 'SELECT name FROM condition_object WHERE id = ?',
            Bind  => [ \$Param{ObjectID} ],
            Limit => 1,
        );
    }
    elsif ( $Param{Name} ) {
        return if !$Self->{DBObject}->Prepare(
            SQL   => 'SELECT id FROM condition_object WHERE name = ?',
            Bind  => [ \$Param{Name} ],
            Limit => 1,
        );
    }

    # fetch the result
    my $Lookup;
    while ( my @Row = $Self->{DBObject}->FetchrowArray() ) {
        $Lookup = $Row[0];
    }

    return $Lookup;
}

=item ObjectList()

Returns a list of all condition objects as hash reference

    my $ConditionObjectsRef = $ConditionObject->ObjectList(
        UserID => 1,
    );

The returned hash reference contains entries like this:

    $ConditionObject{ObjectID} = 'ObjectName'

=cut

sub ObjectList {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{UserID} ) {
        $Self->{LogObject}->Log(
            Priority => 'error',
            Message  => "Need UserID!",
        );
        return;
    }

    # prepare SQL statement
    return if !$Self->{DBObject}->Prepare(
        SQL => 'SELECT id, name FROM condition_object',
    );

    # fetch the result
    my %ObjectList;
    while ( my @Row = $Self->{DBObject}->FetchrowArray() ) {
        $ObjectList{ $Row[0] } = $Row[1];
    }

    return \%ObjectList;
}

=item ObjectDelete()

Deletes a condition object.

    my $Success = $ConditionObject->ObjectDelete(
        ObjectID => 123,
        UserID   => 1,
    );

=cut

sub ObjectDelete {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(ObjectID UserID)) {
        if ( !$Param{$Argument} ) {
            $Self->{LogObject}->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );
            return;
        }
    }

    # delete condition object from database
    return if !$Self->{DBObject}->Do(
        SQL => 'DELETE FROM condition_object '
            . 'WHERE id = ?',
        Bind => [ \$Param{ObjectID} ],
    );

    return 1;
}

=item ObjectSelectorList()

Returns a list of all selectors available for the given object id and condition id as hash reference

    my $SelectorList = $ConditionObject->ObjectSelectorList(
        ObjectID    => 1234,
        ConditionID => 5,
        UserID      => 1,
    );

Returns a hash reference like this (for workorder objects)

    $SelectorList = {
        10    => '1 - WorkorderTitle of Workorder 1',
        12    => '2 - WorkorderTitle of Workorder 2',
        34    => '3 - WorkorderTitle of Workorder 3',
        'any' => 'any',
        'all' => 'all',
    }

or for change objects:

    $SelectorList = {
        456 => 'Change# 2010011610000618',
    }

=cut

sub ObjectSelectorList {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(ObjectID ConditionID UserID)) {
        if ( !$Param{$Argument} ) {
            $Self->{LogObject}->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );
            return;
        }
    }

    # lookup object name
    my $ObjectName = $Self->ObjectLookup(
        ObjectID => $Param{ObjectID},
    );

    # define known objects and function calls
    my %ObjectAction = (
        ITSMChange    => '_ObjectSelectorListITSMChange',
        ITSMWorkOrder => '_ObjectSelectorListITSMWorkOrder',
    );

    # check for manageable object
    if ( !exists $ObjectAction{$ObjectName} ) {
        $Self->{LogObject}->Log(
            Priority => 'error',
            Message  => "No object action for $ObjectName found!",
        );
        return;
    }

    # get the name of the action subroutine
    my $ActionSub = $ObjectAction{$ObjectName};

    # execute the action subroutine
    my $SelectorList = $Self->$ActionSub(
        ConditionID => $Param{ConditionID},
        UserID      => $Param{UserID},
    ) || {};

    return $SelectorList;
}

=item ObjectCompareValueList()

Returns a list of available CompareValues for the given object id and attribute id as hash reference.

    my $CompareValueList = $ConditionObject->ObjectCompareValueList(
        ObjectID      => 1234,
        AttributeName => 'WorkOrderStateID',
        UserID        => 1,
    );

Returns a hash reference like this, for a workorder object and the attribute 'WorkOrderStateID':

    $CompareValueList = {
        10    => 'created',
        12    => 'accepted',
        13    => 'ready',
        14    => 'in progress',
        15    => 'closed',
        16    => 'canceled',
    }

=cut

sub ObjectCompareValueList {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(ObjectID AttributeName UserID)) {
        if ( !$Param{$Argument} ) {
            $Self->{LogObject}->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );
            return;
        }
    }

    # lookup object name
    my $ObjectName = $Self->ObjectLookup(
        ObjectID => $Param{ObjectID},
    );

    # define known objects and function calls
    my %ObjectAction = (
        ITSMChange    => '_ObjectCompareValueListITSMChange',
        ITSMWorkOrder => '_ObjectCompareValueListITSMWorkOrder',
    );

    # check for manageable object
    if ( !exists $ObjectAction{$ObjectName} ) {
        $Self->{LogObject}->Log(
            Priority => 'error',
            Message  => "No object action for $ObjectName found!",
        );
        return;
    }

    # get the name of the action subroutine
    my $ActionSub = $ObjectAction{$ObjectName};

    # execute the action subroutine
    my $CompareValueList = $Self->$ActionSub(
        AttributeName => $Param{AttributeName},
        UserID        => $Param{UserID},
    ) || {};

    return $CompareValueList;
}

=item ObjectDataGet()

Return the data of a given type and selector of a certain object.

    my $ObjectDataRef = $ConditionObject->ObjectDataGet(
        ConditionID => 1234,
        ObjectName  => 'ITSMChange',    # or ObjectID
        ObjectID    => 1,               # or ObjectName
        Selector    => '123',           #  ( ObjectKey | any | all )
        UserID      => 1,
    );

=cut

sub ObjectDataGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(ConditionID Selector UserID)) {
        if ( !$Param{$Argument} ) {
            $Self->{LogObject}->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );
            return;
        }
    }

    # either ObjectName or ObjectID must be passed
    if ( !$Param{ObjectName} && !$Param{ObjectID} ) {
        $Self->{LogObject}->Log(
            Priority => 'error',
            Message  => 'ObjectName ID or ObjectID!',
        );
        return;
    }

    # check that not both ObjectName and ObjectID are given
    if ( $Param{ObjectName} && $Param{ObjectID} ) {
        $Self->{LogObject}->Log(
            Priority => 'error',
            Message  => 'Need either ObjectName OR ObjectID - not both!',
        );
        return;
    }

    # set object name
    my $ObjectName = $Param{ObjectName};
    if ( $Param{ObjectID} ) {
        $ObjectName = $Self->ObjectLookup(
            ObjectID => $Param{ObjectID},
        );
    }

    # get object type
    my $ObjectType = $ObjectName;

    # define known objects and function calls
    my %ObjectAction = (
        ITSMChange       => '_ObjectDataGetITSMChange',
        ITSMWorkOrder    => '_ObjectDataGetITSMWorkOrder',
        ITSMWorkOrderAll => '_ObjectDataGetITSMWorkOrderAll',
    );

    # define the needed selectors
    my %ObjectSelector = (
        ITSMChange    => 'ChangeID',
        ITSMWorkOrder => 'WorkOrderID',
    );

    # check for manageable object
    if ( !exists $ObjectAction{$ObjectType} ) {
        $Self->{LogObject}->Log(
            Priority => 'error',
            Message  => "No object action for $ObjectType found!",
        );
        return;
    }

    # extract needed sub and selector
    my $ActionSub      = $ObjectAction{$ObjectType};
    my $ActionSelector = $ObjectSelector{$ObjectType};

    # check for available function
    if ( !$Self->can($ActionSub) ) {
        $Self->{LogObject}->Log(
            Priority => 'error',
            Message  => "No function '$ActionSub' available for '$ObjectType'!",
        );
        return;
    }

    # handle 'all' or 'any' selector in a special way
    if ( $Param{Selector} =~ m{ ( all | any ) }xms ) {

        # get function name for getting all objects
        $ActionSub = $ObjectAction{ $ObjectType . 'All' };

        # get all objects
        my $AllObjects = $Self->$ActionSub(
            ConditionID     => $Param{ConditionID},
            $ActionSelector => $Param{Selector},
            UserID          => $Param{UserID},
        ) || [];

        # return object data
        return $AllObjects;
    }

    # get object data
    my @ObjectData;
    push @ObjectData, $Self->$ActionSub(
        ConditionID     => $Param{ConditionID},
        $ActionSelector => $Param{Selector},
        UserID          => $Param{UserID},
    ) || {};

    # return object data
    return \@ObjectData;
}

=begin Internal:

=item _ObjectDataGetITSMChange()

Returns the change data as hash reference.

    my $Change = $ConditionObject->_ObjectDataGetITSMChange();

=cut

sub _ObjectDataGetITSMChange {
    my ( $Self, %Param ) = @_;

    # get change data as anon hash ref
    my $Change = $Self->{ChangeObject}->ChangeGet(%Param) || {};

    # return change data
    return $Change;
}

=item _ObjectDataGetITSMWorkOrder()

Returns the workorder data as hash reference.

    my $WorkOrder = $ConditionObject->_ObjectDataGetITSMWorkOrder();

=cut

sub _ObjectDataGetITSMWorkOrder {
    my ( $Self, %Param ) = @_;

    # get workorder data as anon hash ref
    my $WorkOrder = $Self->{WorkOrderObject}->WorkOrderGet(%Param) || {};

    # return workorder data
    return $WorkOrder;
}

=item _ObjectDataGetITSMWorkOrderAll()

Returns an array reference with hash references of all workorder data of a change.

    my $WorkOrderIDsRef = $ConditionObject->_ObjectDataGetITSMWorkOrderAll();

=cut

sub _ObjectDataGetITSMWorkOrderAll {
    my ( $Self, %Param ) = @_;

    # get condition
    my $ConditionData = $Self->ConditionGet(
        ConditionID => $Param{ConditionID},
        UserID      => $Param{UserID},
    );

    # check for condition
    return if !$ConditionData;

    # get all workorder ids of change
    my $WorkOrderIDs = $Self->{WorkOrderObject}->WorkOrderList(
        ChangeID => $ConditionData->{ChangeID},
        UserID   => $Param{UserID},
    );

    # check for workorder ids
    return if !$WorkOrderIDs;
    return if ref $WorkOrderIDs ne 'ARRAY';
    return if !@{$WorkOrderIDs};

    # get workorder data
    my @WorkOrderData;
    WORKORDERID:
    for my $WorkOrderID ( @{$WorkOrderIDs} ) {
        my $WorkOrder = $Self->{WorkOrderObject}->WorkOrderGet(
            WorkOrderID => $WorkOrderID,
            UserID      => $Param{UserID},
        );

        # check workorder
        next WORKORDERID if !$WorkOrder;

        # add workorder to return array
        push @WorkOrderData, $WorkOrder;
    }

    # return workorder data
    return \@WorkOrderData;
}

=item _ObjectSelectorListITSMChange()

Returns a list of all selectors available for the given change object id and condition id as hash reference

    my $SelectorList = $ConditionObject->_ObjectSelectorListITSMChange(
        ObjectID    => 1234,
        ConditionID => 5,
        UserID      => 1,
    );

Returns a hash reference like this:

    $SelectorList = {
        456 => 'Change# 2010011610000618',
    }

=cut

sub _ObjectSelectorListITSMChange {
    my ( $Self, %Param ) = @_;

    # get condition data
    my $ConditionData = $Self->ConditionGet(
        ConditionID => $Param{ConditionID},
        UserID      => $Param{UserID},
    );

    # check for error
    return if !$ConditionData;

    # get change data
    my $ChangeData = $Self->{ChangeObject}->ChangeGet(
        ChangeID => $ConditionData->{ChangeID},
        UserID   => $Param{UserID},
    );

    # check error
    return if !$ConditionData;

    # build selector list
    my %SelectorList;
    if ($ChangeData) {
        $SelectorList{ $ChangeData->{ChangeID} } = $ChangeData->{ChangeNumber};
    }

    return \%SelectorList;
}

=item _ObjectSelectorListITSMWorkOrder()

Returns a list of all selectors available for the given workorder object id and condition id as hash reference

    my $SelectorList = $ConditionObject->_ObjectSelectorListITSMWorkOrder(
        ObjectID    => 1234,
        ConditionID => 5,
        UserID      => 1,
    );

Returns a hash reference like this:

    $SelectorList = {
        10    => '1 - WorkorderTitle of Workorder 1',
        12    => '2 - WorkorderTitle of Workorder 2',
        34    => '3 - WorkorderTitle of Workorder 3',
        'any' => 'any',
        'all' => 'all',
    }

=cut

sub _ObjectSelectorListITSMWorkOrder {
    my ( $Self, %Param ) = @_;

    # get condition
    my $ConditionData = $Self->ConditionGet(
        ConditionID => $Param{ConditionID},
        UserID      => $Param{UserID},
    );

    # check for condition
    return if !$ConditionData;

    # get all workorder ids of change
    my $WorkOrderIDs = $Self->{WorkOrderObject}->WorkOrderList(
        ChangeID => $ConditionData->{ChangeID},
        UserID   => $Param{UserID},
    );

    # check for workorder ids
    return if !$WorkOrderIDs;
    return if ref $WorkOrderIDs ne 'ARRAY';

    # build selector list
    my %SelectorList;
    for my $WorkOrderID ( @{$WorkOrderIDs} ) {

        # get workorder data
        my $WorkOrderData = $Self->{WorkOrderObject}->WorkOrderGet(
            WorkOrderID => $WorkOrderID,
            UserID      => $Param{UserID},
        );

        $SelectorList{ $WorkOrderData->{WorkOrderID} }
            = $WorkOrderData->{WorkOrderNumber} . ' - ' . $WorkOrderData->{WorkOrderTitle};
    }

    # add 'any' and 'all'
    $SelectorList{'any'} = 'any';
    $SelectorList{'all'} = 'all';

    return \%SelectorList;
}

=item _ObjectCompareValueListITSMChange()

Returns a list of available CompareValues for the given attribute id of a change object as hash reference.

    my $CompareValueList = $ConditionObject->_ObjectCompareValueListITSMChange(
        AttributeName => 'PriorityID',
        UserID        => 1,
    );

Returns a hash reference like this, for the change attribute 'Priority':

    $CompareValueList = {
        23    => '1 very low',
        24    => '2 low',
        25    => '3 normal',
        26    => '4 high',
        27    => '5 very high',
    }

=cut

sub _ObjectCompareValueListITSMChange {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(AttributeName UserID)) {
        if ( !$Param{$Argument} ) {
            $Self->{LogObject}->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );
            return;
        }
    }

    # to store the list
    my $CompareValueList = {};

    # CategoryID, ImpactID, PriorityID
    if ( $Param{AttributeName} =~ m{ \A ( Category | Impact | Priority ) ID \z }xms ) {

        # remove 'ID' at the end of attribute
        my $Type = $1;

        # get the category or impact or priority list
        $CompareValueList = $Self->{ChangeObject}->ChangePossibleCIPGet(
            Type   => $Type,
            UserID => $Param{UserID},
        );
    }

    # ChangeStateID
    elsif ( $Param{AttributeName} eq 'ChangeStateID' ) {

        # get change state list
        $CompareValueList = $Self->{ChangeObject}->ChangePossibleStatesGet(
            UserID => $Param{UserID},
        );
    }

    return $CompareValueList;
}

=item _ObjectCompareValueListITSMWorkOrder()

Returns a list of available CompareValues for the given attribute id of a workorder object as hash reference.

    my $CompareValueList = $ConditionObject->_ObjectCompareValueListITSMWorkOrder(
        AttributeName => 'WorkOrderStateID',
        UserID        => 1,
    );

Returns a hash reference like this, for the workorder attribute 'WorkOrderStateID':

    $CompareValueList = {
        10    => 'created',
        12    => 'accepted',
        13    => 'ready',
        14    => 'in progress',
        15    => 'closed',
        16    => 'canceled',
    }
=cut

sub _ObjectCompareValueListITSMWorkOrder {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(AttributeName UserID)) {
        if ( !$Param{$Argument} ) {
            $Self->{LogObject}->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );
            return;
        }
    }

    # to store the list
    my $CompareValueList = {};

    # WorkOrderStateID
    if ( $Param{AttributeName} eq 'WorkOrderStateID' ) {

        # get workorder state list
        $CompareValueList = $Self->{WorkOrderObject}->WorkOrderPossibleStatesGet(
            UserID => $Param{UserID},
        );
    }

    # WorkOrderTypeID
    elsif ( $Param{AttributeName} eq 'WorkOrderTypeID' ) {

        # get workorder type list
        $CompareValueList = $Self->{WorkOrderObject}->WorkOrderTypeList(
            UserID => $Param{UserID},
        );
    }

    return $CompareValueList;
}

1;

=end Internal:

=back

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (http://otrs.org/).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see http://www.gnu.org/licenses/agpl.txt.

=cut

=head1 VERSION

$Revision: 1.20 $ $Date: 2010-01-22 12:42:20 $

=cut
