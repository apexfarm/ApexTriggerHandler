public class Triggers {
    public static final Boolean WHEN_ALWAYS = true;
    public static final Skips skips = new Skips();

    public static Manager prepare() {
        return new Manager();
    }

    public class Manager {
        public final Props props { get; private set; }
        public final Context context { get; private set; }

        Boolean canBind = false;

        @TestVisible
        private Manager() {
            this(new Props());
        }

        @TestVisible
        private Manager(Props props) {
            this.props = props;
            this.context = new Context(props);
        }

        public Manager beforeInsert() {
            canBind = props.operationType == TriggerOperation.BEFORE_INSERT;
            return this;
        }

        public Manager afterInsert() {
            canBind = props.operationType == TriggerOperation.AFTER_INSERT;
            return this;
        }

        public Manager beforeUpdate() {
            canBind = props.operationType == TriggerOperation.BEFORE_UPDATE;
            return this;
        }

        public Manager afterUpdate() {
            canBind = props.operationType == TriggerOperation.AFTER_UPDATE;
            return this;
        }

        public Manager beforeDelete() {
            canBind = props.operationType == TriggerOperation.BEFORE_DELETE;
            return this;
        }

        public Manager afterDelete() {
            canBind = props.operationType == TriggerOperation.AFTER_DELETE;
            return this;
        }

        public Manager afterUndelete() {
            canBind = props.operationType == TriggerOperation.AFTER_UNDELETE;
            return this;
        }

        public Manager bind(Handler handler) {
            if (canBind) {
                Boolean isImplementation = false;
                switch on props.operationType {
                    when BEFORE_INSERT {
                        isImplementation = handler instanceOf BeforeInsert;
                    }
                    when AFTER_INSERT {
                        isImplementation = handler instanceOf AfterInsert;
                    }
                    when BEFORE_UPDATE {
                        isImplementation = handler instanceOf BeforeUpdate;
                    }
                    when AFTER_UPDATE {
                        isImplementation = handler instanceOf AfterUpdate;
                    }
                    when BEFORE_DELETE {
                        isImplementation = handler instanceOf BeforeDelete;
                    }
                    when AFTER_DELETE {
                        isImplementation = handler instanceOf AfterDelete;
                    }
                    when AFTER_UNDELETE {
                        isImplementation = handler instanceOf AfterUndelete;
                    }
                    when else {
                    }
                }
                if (isImplementation) {
                    context.handlers.add(handler);
                }
            }
            return this;
        }

        public void execute() {
            context.execute();
        }
    }

    public class Skips {
        private final Set<String> skipHandlerNames = new Set<String>();

        public void add(type handlerType) {
            skipHandlerNames.add(getHandlerName(handlerType));
        }

        public void remove(type handlerType) {
            skipHandlerNames.remove(getHandlerName(handlerType));
        }

        public Boolean contains(type handlerType) {
            return contains(getHandlerName(handlerType));
        }

        public void clear() {
            skipHandlerNames.clear();
        }

        private Boolean contains(String handlerName) {
            return skipHandlerNames.contains(handlerName);
        }

        private Boolean contains(Handler handler) {
            return contains(getHandlerName(handler));
        }

        @TestVisible
        private String getHandlerName(Type handlerType) {
            String fullName = handlerType.getName();
            if (fullName.indexOf('.') != -1) {
                return fullName.substring(fullName.indexOf('.') + 1);
            }
            return fullName;
        }

        private String getHandlerName(Handler handler) {
            String printName = String.valueOf(handler);
            return printName.substring(0, printName.indexOf(':'));
        }
    }

    public class Context {
        public final Map<String, Object> state { get; private set; }
        public final Skips skips { get; private set; }
        public final Props props { get; private set; }

        private final List<Handler> handlers = new List<Handler>();
        private Integer currIndex = -1;
        private Boolean isExecutingCriteria = false;

        private Context(Props props) {
            this.props = props;
            this.state = new Map<String, Object>();
            this.skips = Triggers.skips;
        }

        private void reset() {
            this.currIndex = -1;
        }

        private Boolean hasNext() {
            return this.currIndex < this.handlers.size() - 1;
        }

        public void stop() {
            this.currIndex = this.handlers.size();
        }

        public void next() {
            if (!this.isExecutingCriteria) {
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

        private void runNext() {
            this.currIndex++;
            Handler handler = this.handlers[this.currIndex];
            this.isExecutingCriteria = true;
            if (!this.skips.contains(handler) && handler.criteria(this) == true) {
                this.isExecutingCriteria = false;
                switch on this.props.operationType {
                    when BEFORE_INSERT {
                        ((BeforeInsert)handler).beforeInsert(this);
                    }
                    when AFTER_INSERT {
                        ((AfterInsert)handler).afterInsert(this);
                    }
                    when BEFORE_UPDATE {
                        ((BeforeUpdate)handler).beforeUpdate(this);
                    }
                    when AFTER_UPDATE {
                        ((AfterUpdate)handler).afterUpdate(this);
                    }
                    when BEFORE_DELETE {
                        ((BeforeDelete)handler).beforeDelete(this);
                    }
                    when AFTER_DELETE {
                        ((AfterDelete)handler).afterDelete(this);
                    }
                    when AFTER_UNDELETE {
                        ((AfterUndelete)handler).afterUndelete(this);
                    }
                    when else {
                    }
                }
            } else {
                this.isExecutingCriteria = false;
            }
        }
    }

    public class Props {
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
            this.isExecuting = Trigger.isExecuting;
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
        private void setSObjectType() {
            if (this.oldList != null ) {
                this.sObjectType = this.oldList.getSobjectType();
            } else if (this.newList != null ) {
                this.sObjectType = this.newList.getSObjectType();
            }
        }

        public List<Object> getValues(SObjectField field) {
            List<Object> values = new List<Object>();
            List<SObject> objects = new List<SObject>();

            if (this.isInsert || this.isUpdate || this.isUndelete) {
                objects = this.newList;
            } else if (this.isDelete) {
                objects = this.oldList;
            }

            String fieldName = field.getDescribe().getName();
            for (SObject obj : objects) {
				values.add(obj.get(fieldName));
            }
            return values;
        }

        @TestVisible
        private Boolean isChanged(Id objectId, SObjectField field) {
            if (this.isUpdate) {
                String fieldName = field.getDescribe().getName();
                Object oldValue = this.oldMap.get(objectId).get(fieldName);
                Object newValue = this.newMap.get(objectId).get(fieldName);
                return oldValue != newValue;
            }
            return false;
        }

        public Boolean isChanged(SObjectField field1) {
            return isChangedAny(new List<SObjectField> { field1 });
        }

        public Boolean isChangedAny(SObjectField field1, SObjectField field2) {
            return isChangedAny(new List<SObjectField> { field1, field2 });
        }

        public Boolean isChangedAny(SObjectField field1, SObjectField field2, SObjectField field3) {
            return isChangedAny(new List<SObjectField> { field1, field2, field3 });
        }

        public Boolean isChangedAny(List<SObjectField> fields) {
            return filterChangedAny(fields).size() > 0;
        }

        public Boolean isChangedAll(SObjectField field1, SObjectField field2) {
            return isChangedAll(new List<SObjectField> { field1, field2 });
        }

        public Boolean isChangedAll(SObjectField field1, SObjectField field2, SObjectField field3) {
            return isChangedAll(new List<SObjectField> { field1, field2, field3 });
        }

        public Boolean isChangedAll(List<SObjectField> fields) {
            return filterChangedAll(fields).size() > 0;
        }

        public Set<Id> filterChanged(SObjectField field1) {
            return filterChangedAny(new List<SObjectField> { field1 });
        }

        public Set<Id> filterChangedAny(SObjectField field1, SObjectField field2) {
            return filterChangedAny(new List<SObjectField> { field1, field2 });
        }

        public Set<Id> filterChangedAny(SObjectField field1, SObjectField field2, SObjectField field3) {
            return filterChangedAny(new List<SObjectField> { field1, field2, field3 });
        }

        public Set<Id> filterChangedAny(List<SObjectField> fields) {
            Set<Id> changedIds = new Set<Id>();
            if (this.isUpdate) {
                for(Id objectId : this.newMap.keySet()) {
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

        public Set<Id> filterChangedAll(SObjectField field1, SObjectField field2) {
            return filterChangedAll(new List<SObjectField> { field1, field2 });
        }

        public Set<Id> filterChangedAll(SObjectField field1, SObjectField field2, SObjectField field3) {
            return filterChangedAll(new List<SObjectField> { field1, field2, field3 });
        }

        public Set<Id> filterChangedAll(List<SObjectField> fields) {
            Set<Id> changedIds = new Set<Id>();
            if (this.isUpdate) {
                changedIds = this.newMap.keySet();
                for(Id objectId : this.newMap.keySet()) {
                    for (SObjectField field : fields) {
                        if (!isChanged(objectId, field)) {
                            changedIds.remove(objectId);
                            break;
                        }
                    }
                }
            }
            return changedIds;
        }
    }

    public interface Handler {
        Boolean criteria(Context context);
    }

    public interface BeforeInsert {
        void beforeInsert(Context context);
    }

    public interface AfterInsert {
        void afterInsert(Context context);
    }

    public interface BeforeUpdate {
        void beforeUpdate(Context context);
    }

    public interface AfterUpdate {
        void afterUpdate(Context context);
    }

    public interface BeforeDelete {
        void beforeDelete(Context context);
    }

    public interface AfterDelete {
        void afterDelete(Context context);
    }

    public interface AfterUndelete {
        void afterUndelete(Context context);
    }
}