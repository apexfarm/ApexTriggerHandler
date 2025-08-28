/**
 * BSD 3-Clause License
 *
 * Copyright (c) 2020, Jianfeng Jin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its
 *    contributors may be used to endorse or promote products derived from
 *    this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

public class Triggers {
    public static final Boolean WHEN_ALWAYS = true;
    public static final SkipsImpl skips = new SkipsImpl();
    public static final StateImpl state = new StateImpl();
    @TestVisible
    public static TriggerHandlerSettings__c HANDLER_SETTINGS {
        get {
            if (HANDLER_SETTINGS == null) {
                HANDLER_SETTINGS = TriggerHandlerSettings__c.getInstance();
            }

            if (HANDLER_SETTINGS.Name == null) {
                HANDLER_SETTINGS = new TriggerHandlerSettings__c();
                HANDLER_SETTINGS.Name = 'Default';
                HANDLER_SETTINGS.BypassTriggers__c = false;
                HANDLER_SETTINGS.BypassRegistry__c = false;
            }
            return HANDLER_SETTINGS;
        }
        private set;
    }

    @TestVisible
    private static Loader LOADER {
        get {
            if (LOADER == null) {
                LOADER = new TriggersLoader();
            }
            return LOADER;
        }
        set;
    }

    public static Manager prepare() {
        Props props = new Props();
        return new ManagerImpl(props);
    }

    @TestVisible
    private static Manager prepare(TriggerOperation operationType, List<SObject> oldList, List<SObject> newList) {
        Props props = new Props(operationType, oldList, newList);
        return new ManagerImpl(props);
    }

    @TestVisible
    private class ManagerImpl implements Manager {
        public final Props props { get; private set; }
        public final Context context { get; private set; }

        Boolean canBind = true;

        private ManagerImpl(Props props) {
            this.props = props;
            this.context = new Context(this.props);
        }

        public Manager beforeInsert() {
            this.canBind = this.props.operationType == TriggerOperation.BEFORE_INSERT;
            return this;
        }

        public Manager afterInsert() {
            this.canBind = this.props.operationType == TriggerOperation.AFTER_INSERT;
            return this;
        }

        public Manager beforeUpdate() {
            this.canBind = this.props.operationType == TriggerOperation.BEFORE_UPDATE;
            return this;
        }

        public Manager afterUpdate() {
            this.canBind = this.props.operationType == TriggerOperation.AFTER_UPDATE;
            return this;
        }

        public Manager beforeDelete() {
            this.canBind = this.props.operationType == TriggerOperation.BEFORE_DELETE;
            return this;
        }

        public Manager afterDelete() {
            this.canBind = this.props.operationType == TriggerOperation.AFTER_DELETE;
            return this;
        }

        public Manager afterUndelete() {
            this.canBind = this.props.operationType == TriggerOperation.AFTER_UNDELETE;
            return this;
        }

        private void loadRegistry() {
            if (HANDLER_SETTINGS.BypassRegistry__c == true) {
                return;
            }

            this.canBind = true;

            List<Type> handlerTypes = LOADER.load(
                String.valueOf(this.props.sObjectType),
                this.props.operationType.name()
            );

            for (Type handlerType : handlerTypes) {
                this.bind(handlerType);
            }

            this.canBind = false;
        }

        public Manager bind(Type handlerType) {
            if (handlerType == null) {
                return this;
            }

            if (!this.canBind) {
                return this;
            }

            if (!Handler.class.isAssignableFrom(handlerType)) {
                throw new IllegalArgumentException('Type [' + handlerType + '] is not a Handler type.');
            }

            Boolean isImplemented = false;
            switch on this.props.operationType {
                when BEFORE_INSERT {
                    isImplemented = BeforeInsert.class.isAssignableFrom(handlerType);
                }
                when AFTER_INSERT {
                    isImplemented = AfterInsert.class.isAssignableFrom(handlerType);
                }
                when BEFORE_UPDATE {
                    isImplemented = BeforeUpdate.class.isAssignableFrom(handlerType);
                }
                when AFTER_UPDATE {
                    isImplemented = AfterUpdate.class.isAssignableFrom(handlerType);
                }
                when BEFORE_DELETE {
                    isImplemented = BeforeDelete.class.isAssignableFrom(handlerType);
                }
                when AFTER_DELETE {
                    isImplemented = AfterDelete.class.isAssignableFrom(handlerType);
                }
                when AFTER_UNDELETE {
                    isImplemented = AfterUndelete.class.isAssignableFrom(handlerType);
                }
                when else {
                }
            }

            if (isImplemented) {
                this.context.handlerTypes.add(handlerType);
            }

            return this;
        }

        public Manager bind(List<Type> handlerTypes) {
            return this;
        }

        public Manager bind(String handlerName) {
            if (String.isBlank(handlerName)) {
                return this;
            }

            if (!this.canBind) {
                return this;
            }

            Type handlerType = Type.forName(handlerName);
            return this.bind(handlerType);
        }

        public Manager bind(List<String> handlerNames) {
            return this;
        }

        public void execute() {
            if (HANDLER_SETTINGS.BypassTriggers__c == true) {
                return;
            }
            this.context.execute();
            this.props.isExecuting = false;
        }
    }

    public class SkipsImpl implements Skips {
        @TestVisible
        private final Set<Type> skippedHandlers = new Set<Type>();

        public void add(type handlerType) {
            this.skippedHandlers.add(handlerType);
        }

        public void remove(type handlerType) {
            this.skippedHandlers.remove(handlerType);
        }

        public Boolean contains(type handlerType) {
            return this.skippedHandlers.contains(handlerType);
        }

        @TestVisible
        private Boolean contains(Handler handler) {
            return contains(getHandlerType(handler));
        }

        public void clear() {
            this.skippedHandlers.clear();
        }

        private Type getHandlerType(Handler handler) {
            String printName = String.valueOf(handler);
            String typeName = printName.substring(0, printName.indexOf(':'));
            return Type.forName(typeName);
        }
    }

    public class StateImpl implements State {
        private final Map<Type, Object> states = new Map<Type, Object>();

        public Boolean contains(Type stateType) {
            return this.states.containsKey(stateType);
        }

        public void remove(Type stateType) {
            this.states.remove(stateType);
        }

        public void clear() {
            this.states.clear();
        }

        public void put(Type stateType, Object state) {
            if (stateType == null || state == null) {
                return;
            }

            this.states.put(stateType, state);
        }

        public Object get(Type stateType) {
            if (stateType == null) {
                return null;
            }

            if (!this.states.containsKey(stateType)) {
                State state = (State) stateType.newInstance();
                this.states.put(stateType, state);
            }
            return this.states.get(stateType);
        }
    }

    // #region Context
    public class Context implements IContext {
        public final SkipsImpl skips { get; private set; }
        public final Props props { get; private set; }
        public final State state { get; private set; }

        private final List<Type> handlerTypes = new List<Type>();
        private Integer currIndex = -1;
        private Boolean isExecutingshouldExecute = false;

        private Context(Props props) {
            this.skips = Triggers.skips;
            this.state = Triggers.state;
            this.props = props;
        }

        public void stop() {
            this.currIndex = this.handlerTypes.size();
        }

        public void next() {
            // prevent calling context.next() in shouldExecute phase
            if (!this.isExecutingshouldExecute) {
                while (hasNext()) {
                    runNext();
                }
            }
        }

        private void execute() {
            reset();
            while (hasNext()) {
                runNext();
            }
        }

        private void reset() {
            this.currIndex = -1;
        }

        private Boolean hasNext() {
            return this.currIndex < this.handlerTypes.size() - 1;
        }

        private void runNext() {
            this.currIndex++;
            Type handlerType = this.handlerTypes[this.currIndex];
            Handler handler = (Handler) handlerType.newInstance();

            this.isExecutingshouldExecute = true;
            if (!this.skips.contains(handler) && handler.shouldExecute(this) == true) {
                this.isExecutingshouldExecute = false;
                switch on this.props.operationType {
                    when BEFORE_INSERT {
                        ((BeforeInsert) handler).beforeInsert(this);
                    }
                    when AFTER_INSERT {
                        ((AfterInsert) handler).afterInsert(this);
                    }
                    when BEFORE_UPDATE {
                        ((BeforeUpdate) handler).beforeUpdate(this);
                    }
                    when AFTER_UPDATE {
                        ((AfterUpdate) handler).afterUpdate(this);
                    }
                    when BEFORE_DELETE {
                        ((BeforeDelete) handler).beforeDelete(this);
                    }
                    when AFTER_DELETE {
                        ((AfterDelete) handler).afterDelete(this);
                    }
                    when AFTER_UNDELETE {
                        ((AfterUndelete) handler).afterUndelete(this);
                    }
                    when else {
                    }
                }
            } else {
                this.isExecutingshouldExecute = false;
            }
        }
    }

    public class Props implements IProps {
        // Standard Properties
        @TestVisible
        public Boolean isExecuting { get; private set; }
        @TestVisible
        public Boolean isBefore { get; private set; }
        @TestVisible
        public Boolean isAfter { get; private set; }
        @TestVisible
        public Boolean isInsert { get; private set; }
        @TestVisible
        public Boolean isUpdate { get; private set; }
        @TestVisible
        public Boolean isDelete { get; private set; }
        @TestVisible
        public Boolean isUndelete { get; private set; }
        @TestVisible
        public List<SObject> oldList { get; private set; }
        @TestVisible
        public Map<Id, SObject> oldMap { get; private set; }
        @TestVisible
        public List<SObject> newList { get; private set; }
        @TestVisible
        public Map<Id, SObject> newMap { get; private set; }
        @TestVisible
        public TriggerOperation operationType { get; private set; }
        @TestVisible
        public Integer size { get; private set; }

        // Custom Properties
        @TestVisible
        public SObjectType sObjectType { get; private set; }

        @TestVisible
        private Props() {
            this.isExecuting = true;
            this.isBefore = Trigger.isBefore;
            this.isAfter = Trigger.isAfter;
            this.isInsert = Trigger.isInsert;
            this.isUpdate = Trigger.isUpdate;
            this.isDelete = Trigger.isDelete;
            this.isUndelete = Trigger.isUndelete;
            this.oldList = Trigger.old;
            this.oldMap = Trigger.oldMap;
            this.newList = Trigger.new;
            this.newMap = Trigger.newMap;
            this.operationType = Trigger.operationType;
            this.size = Trigger.size;
            this.setSObjectType();
        }

        @TestVisible
        private Props(TriggerOperation operationType, List<SObject> oldList, List<SObject> newList) {
            this.isExecuting = true;
            this.operationType = operationType;
            this.isBefore = false;
            this.isAfter = false;
            this.isInsert = false;
            this.isUpdate = false;
            this.isDelete = false;
            this.isUndelete = false;
            switch on operationType {
                when BEFORE_INSERT {
                    this.isBefore = true;
                    this.isInsert = true;
                    this.oldList = null;
                    this.oldMap = null;
                    this.newList = newList;
                    this.newMap = newList != null ? new Map<Id, SObject>(newList) : null;
                }
                when AFTER_INSERT {
                    this.isAfter = true;
                    this.isInsert = true;
                    this.oldList = null;
                    this.oldMap = null;
                    this.newList = newList;
                    this.newMap = newList != null ? new Map<Id, SObject>(newList) : null;
                }
                when BEFORE_UPDATE {
                    this.isBefore = true;
                    this.isUpdate = true;
                    this.oldList = oldList;
                    this.oldMap = oldList != null ? new Map<Id, SObject>(oldList) : null;
                    this.newList = newList;
                    this.newMap = newList != null ? new Map<Id, SObject>(newList) : null;
                }
                when AFTER_UPDATE {
                    this.isAfter = true;
                    this.isUpdate = true;
                    this.oldList = oldList;
                    this.oldMap = oldList != null ? new Map<Id, SObject>(oldList) : null;
                    this.newList = newList;
                    this.newMap = newList != null ? new Map<Id, SObject>(newList) : null;
                }
                when BEFORE_DELETE {
                    this.isBefore = true;
                    this.isDelete = true;
                    this.oldList = oldList;
                    this.oldMap = oldList != null ? new Map<Id, SObject>(oldList) : null;
                    this.newList = null;
                    this.newMap = null;
                }
                when AFTER_DELETE {
                    this.isAfter = true;
                    this.isDelete = true;
                    this.oldList = oldList;
                    this.oldMap = oldList != null ? new Map<Id, SObject>(oldList) : null;
                    this.newList = null;
                    this.newMap = null;
                }
                when AFTER_UNDELETE {
                    this.isAfter = true;
                    this.isUndelete = true;
                    this.oldList = null;
                    this.oldMap = null;
                    this.newList = newList;
                    this.newMap = newList != null ? new Map<Id, SObject>(newList) : null;
                }
                when else {
                }
            }

            //setSize();
            this.size = 0;
            if (this.oldList != null) {
                this.size = this.oldList.size();
            } else if (this.newList != null) {
                this.size = this.newList.size();
            }
            this.setSObjectType();
        }

        @TestVisible
        private void setSObjectType() {
            if (this.oldList != null) {
                this.sObjectType = this.oldList.getSobjectType();
            } else if (this.newList != null) {
                this.sObjectType = this.newList.getSObjectType();
            }
        }

        @TestVisible
        private Boolean isChanged(Id objectId, SObjectField field) {
            if (this.isUpdate) {
                Object oldValue = this.oldMap.get(objectId).get(field);
                Object newValue = this.newMap.get(objectId).get(field);
                return oldValue != newValue;
            }
            return false;
        }

        public Boolean isChanged(SObjectField field1) {
            return isChangedAny(new List<SObjectField>{ field1 });
        }

        public Boolean isChangedAny(SObjectField field1, SObjectField field2) {
            return isChangedAny(new List<SObjectField>{ field1, field2 });
        }

        public Boolean isChangedAny(SObjectField field1, SObjectField field2, SObjectField field3) {
            return isChangedAny(new List<SObjectField>{ field1, field2, field3 });
        }

        public Boolean isChangedAny(List<SObjectField> fields) {
            return filterChangedAny(fields).size() > 0;
        }

        public Boolean isChangedAll(SObjectField field1, SObjectField field2) {
            return isChangedAll(new List<SObjectField>{ field1, field2 });
        }

        public Boolean isChangedAll(SObjectField field1, SObjectField field2, SObjectField field3) {
            return isChangedAll(new List<SObjectField>{ field1, field2, field3 });
        }

        public Boolean isChangedAll(List<SObjectField> fields) {
            return filterChangedAll(fields).size() > 0;
        }

        public List<Id> filterChanged(SObjectField field1) {
            return filterChangedAny(new List<SObjectField>{ field1 });
        }

        public List<Id> filterChangedAny(SObjectField field1, SObjectField field2) {
            return filterChangedAny(new List<SObjectField>{ field1, field2 });
        }

        public List<Id> filterChangedAny(SObjectField field1, SObjectField field2, SObjectField field3) {
            return filterChangedAny(new List<SObjectField>{ field1, field2, field3 });
        }

        public List<Id> filterChangedAny(List<SObjectField> fields) {
            List<Id> changedIds = new List<Id>();
            if (this.isUpdate) {
                for (SObject newObj : this.newList) {
                    Id objectId = newObj.Id;
                    for (SObjectField field : fields) {
                        if (isChanged(objectId, field)) {
                            changedIds.add(objectId);
                            break;
                        }
                    }
                }
            }
            return changedIds;
        }

        public List<Id> filterChangedAll(SObjectField field1, SObjectField field2) {
            return filterChangedAll(new List<SObjectField>{ field1, field2 });
        }

        public List<Id> filterChangedAll(SObjectField field1, SObjectField field2, SObjectField field3) {
            return filterChangedAll(new List<SObjectField>{ field1, field2, field3 });
        }

        public List<Id> filterChangedAll(List<SObjectField> fields) {
            List<Id> changedIds = new List<Id>();
            if (this.isUpdate) {
                for (SObject newObj : this.newList) {
                    Id objectId = newObj.Id;
                    changedIds.add(objectId);
                    for (SObjectField field : fields) {
                        if (!isChanged(objectId, field)) {
                            changedIds.remove(changedIds.size() - 1);
                            break;
                        }
                    }
                }
            }
            return changedIds;
        }

        public Boolean containsRecordTypeNames(List<String> recordTypeNames) {
            return null;
        }

        public Boolean contains(SObjectField field, List<Object> values) {
            if (values == null || values.isEmpty()) {
                return false;
            }

            List<SObject> objects = new List<SObject>();
            if (this.isInsert || this.isUpdate || this.isUndelete) {
                objects = this.newList;
            } else if (this.isDelete) {
                objects = this.oldList;
            }

            for (SObject obj : objects) {
                if (values.contains(obj.get(field))) {
                    return true;
                }
            }
            return false;
        }

        public List<Id> filterByRecordTypeNames(List<String> recordTypeNames) {
            return null;
        }

        public List<Id> filterBy(SObjectField field, List<Object> values) {
            List<Id> matchedIds = new List<Id>();
            if (values == null || values.isEmpty()) {
                return matchedIds;
            }

            List<SObject> objects = new List<SObject>();
            if (this.isInsert || this.isUpdate || this.isUndelete) {
                objects = this.newList;
            } else if (this.isDelete) {
                objects = this.oldList;
            }

            for (SObject obj : objects) {
                if (values.contains(obj.get(field))) {
                    matchedIds.add(obj.Id);
                }
            }
            return matchedIds;
        }

        public List<Object> getValues(SObjectField field) {
            List<Object> values = new List<Object>();

            List<SObject> objects = new List<SObject>();
            if (this.isInsert || this.isUpdate || this.isUndelete) {
                objects = this.newList;
            } else if (this.isDelete) {
                objects = this.oldList;
            }

            for (SObject obj : objects) {
                values.add(obj.get(field));
            }
            return values;
        }
    }

    // #endregion Context

    //===================
    // #region interfaces
    public interface Loader {
        List<Type> load(String sobjectName, String triggerEventName);
    }

    public interface IContext {
        void stop();
        void next();
    }

    public interface IProps {
        List<Object> getValues(SObjectField field);

        Boolean isChanged(SObjectField field1);
        Boolean isChangedAny(SObjectField field1, SObjectField field2);
        Boolean isChangedAny(SObjectField field1, SObjectField field2, SObjectField field3);
        Boolean isChangedAny(List<SObjectField> fields);
        Boolean isChangedAll(SObjectField field1, SObjectField field2);
        Boolean isChangedAll(SObjectField field1, SObjectField field2, SObjectField field3);
        Boolean isChangedAll(List<SObjectField> fields);
        Boolean containsRecordTypeNames(List<String> recordTypeNames);
        Boolean contains(SObjectField field, List<Object> values);

        List<Id> filterChanged(SObjectField field1);
        List<Id> filterChangedAny(SObjectField field1, SObjectField field2);
        List<Id> filterChangedAny(SObjectField field1, SObjectField field2, SObjectField field3);
        List<Id> filterChangedAny(List<SObjectField> fields);
        List<Id> filterChangedAll(SObjectField field1, SObjectField field2);
        List<Id> filterChangedAll(SObjectField field1, SObjectField field2, SObjectField field3);
        List<Id> filterChangedAll(List<SObjectField> fields);
        List<Id> filterByRecordTypeNames(List<String> recordTypeNames);
        List<Id> filterBy(SObjectField field, List<Object> values);
    }

    public interface State {
        Object get(Type stateType);
        void put(Type stateType, Object state);
        Boolean contains(Type stateType);
        void remove(Type stateType);
        void clear();
    }

    public interface Skips {
        void add(type handlerType);
        Boolean contains(type handlerType);
        void remove(type handlerType);
        void clear();
    }

    public interface Manager {
        Manager beforeInsert();
        Manager afterInsert();
        Manager beforeUpdate();
        Manager afterUpdate();
        Manager beforeDelete();
        Manager afterDelete();
        Manager afterUndelete();

        Manager bind(Type handlerType);
        Manager bind(List<Type> handlerTypes);
        Manager bind(String handlerName);
        Manager bind(List<String> handlerNames);

        void execute();
    }

    public interface Handler {
        Boolean shouldExecute(Context context);
    }

    public interface BeforeInsert extends Handler {
        void beforeInsert(Context context);
    }

    public interface AfterInsert extends Handler {
        void afterInsert(Context context);
    }

    public interface BeforeUpdate extends Handler {
        void beforeUpdate(Context context);
    }

    public interface AfterUpdate extends Handler {
        void afterUpdate(Context context);
    }

    public interface BeforeDelete extends Handler {
        void beforeDelete(Context context);
    }

    public interface AfterDelete extends Handler {
        void afterDelete(Context context);
    }

    public interface AfterUndelete extends Handler {
        void afterUndelete(Context context);
    }
    // #endregion
    //===================
}
