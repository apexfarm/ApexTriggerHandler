public class Triggers {
    public static final Boolean WHEN_ALWAYS = true;

    public TriggerProp triggerProp { get; private set; }
    public Context context { get; private set; }

    Boolean canBind = false;

    @TestVisible
    private Triggers() {
        this(new TriggerProp());
    }

    @TestVisible
    private Triggers(TriggerProp triggerProp) {
        this.triggerProp = triggerProp;
        this.context = new Context(triggerProp);
    }

    // #region Trigger Level Methods
    public static Triggers prepare() {
        return new Triggers();
    }

    public Triggers beforeInsert() {
        canBind = triggerProp.operationType == TriggerOperation.BEFORE_INSERT;
        return this;
    }

    public Triggers afterInsert() {
        canBind = triggerProp.operationType == TriggerOperation.AFTER_INSERT;
        return this;
    }

    public Triggers beforeUpdate() {
        canBind = triggerProp.operationType == TriggerOperation.BEFORE_UPDATE;
        return this;
    }

    public Triggers afterUpdate() {
        canBind = triggerProp.operationType == TriggerOperation.AFTER_UPDATE;
        return this;
    }

    public Triggers beforeDelete() {
        canBind = triggerProp.operationType == TriggerOperation.BEFORE_DELETE;
        return this;
    }

    public Triggers afterDelete() {
        canBind = triggerProp.operationType == TriggerOperation.AFTER_DELETE;
        return this;
    }

    public Triggers afterUndelete() {
        canBind = triggerProp.operationType == TriggerOperation.AFTER_UNDELETE;
        return this;
    }

    public Triggers bind(Handler handler) {
        if (canBind) {
            Boolean isImplementation = false;
            switch on triggerProp.operationType {
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
        context.reset();
        while (context.hasNext()) {
	        context.next();
        }
    }
    // #endregion

    public class TriggerProp {
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

        @TestVisible
        private TriggerProp() {
            this.isExecuting = Trigger.isExecuting;
            this.isBefore = Trigger.isBefore;
            this.isAfter = Trigger.isAfter;
            this.isInsert = Trigger.isInsert;
            this.isUpdate = Trigger.isUpdate;
            this.isDelete = Trigger.isDelete;
            this.isUndelete = Trigger.isUndelete;
            this.oldList = Trigger.old;
            this.oldMap = Trigger.oldMap;
            this.newList = Trigger.old;
            this.newMap = Trigger.newMap;
            this.operationType = Trigger.operationType;
            this.size = Trigger.size;
        }
    }

    public class Context {
        @TestVisible
        public TriggerProp triggerProp { get; private set; }
        public final Map<String, Object> state = new Map<String, Object>();
        private final List<Handler> handlers = new List<Handler>();
        private Integer currIndex = -1;
        private Boolean isWhenFinished = true;
        private Helper helper = null;

        private Context(TriggerProp triggerProp) {
            this.triggerProp = triggerProp;
            this.helper = new Helper(triggerProp);
        }

        public void next() {
            if (isWhenFinished && hasNext()) {
                currIndex++;
                Handler handler = handlers[currIndex];
                isWhenFinished = false;
                if (handler.when(this, helper) == true) {
                    isWhenFinished = true;
                    switch on triggerProp.operationType {
                        when BEFORE_INSERT {
                            ((BeforeInsert)handler).beforeInsert(this, helper);
                        }
                        when AFTER_INSERT {
                            ((AfterInsert)handler).afterInsert(this, helper);
                        }
                        when BEFORE_UPDATE {
                            ((BeforeUpdate)handler).beforeUpdate(this, helper);
                        }
                        when AFTER_UPDATE {
                            ((AfterUpdate)handler).afterUpdate(this, helper);
                        }
                        when BEFORE_DELETE {
                            ((BeforeDelete)handler).beforeDelete(this, helper);
                        }
                        when AFTER_DELETE {
                            ((AfterDelete)handler).afterDelete(this, helper);
                        }
                        when AFTER_UNDELETE {
                            ((AfterUndelete)handler).afterUndelete(this, helper);
                        }
                        when else {
                        }
                    }
                }
            }
        }

        private Boolean hasNext() {
            return currIndex < handlers.size() - 1;
        }

        private void reset() {
            currIndex = -1;
        }
    }

    public class Helper {
        TriggerProp triggerProp;

        @TestVisible
        private Helper(TriggerProp triggerProp) {
            this.triggerProp = triggerProp;
        }

        public List<Object> getValues(SObjectField field) {
            List<Object> values = new List<Object>();
            List<SObject> objects = new List<SObject>();

            if (triggerProp.isInsert || triggerProp.isUpdate || triggerProp.isUndelete) {
                objects = triggerProp.newList;
            } else if (triggerProp.isDelete) {
                objects = triggerProp.oldList;
            }

            String fieldName = field.getDescribe().getName();
            for (SObject obj : objects) {
				values.add(obj.get(fieldName));
            }
            return values;
        }

        @TestVisible
        private Boolean isChanged(Id objectId, SObjectField field) {
            if (triggerProp.isUpdate) {
                String fieldName = field.getDescribe().getName();
                Object oldValue = triggerProp.oldMap.get(objectId).get(fieldName);
                Object newValue = triggerProp.newMap.get(objectId).get(fieldName);
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
            if (triggerProp.isUpdate) {
                for(Id objectId : triggerProp.newMap.keySet()) {
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
            if (triggerProp.isUpdate) {
                changedIds = triggerProp.newMap.keySet();
                for(Id objectId : triggerProp.newMap.keySet()) {
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
        Boolean when(Context context, Helper helper);
    }

    public interface BeforeInsert {
        void beforeInsert(Context context, Helper helper);
    }

    public interface AfterInsert {
        void afterInsert(Context context, Helper helper);
    }

    public interface BeforeUpdate {
        void beforeUpdate(Context context, Helper helper);
    }

    public interface AfterUpdate {
        void afterUpdate(Context context, Helper helper);
    }

    public interface BeforeDelete {
        void beforeDelete(Context context, Helper helper);
    }

    public interface AfterDelete {
        void afterDelete(Context context, Helper helper);
    }

    public interface AfterUndelete {
        void afterUndelete(Context context, Helper helper);
    }
}