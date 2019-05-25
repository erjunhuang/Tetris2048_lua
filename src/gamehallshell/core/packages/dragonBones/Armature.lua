
--------------------------------
-- @module Armature
-- @extend IAnimateble,BaseObject
-- @parent_module db

--------------------------------
-- 
-- @function [parent=#Armature] getSlot 
-- @param self
-- @param #string name
-- @return Slot#Slot ret (return value: db.Slot)
        
--------------------------------
-- 
-- @function [parent=#Armature] getDisplay 
-- @param self
-- @return IArmatureDisplay#IArmatureDisplay ret (return value: db.IArmatureDisplay)
        
--------------------------------
-- 
-- @function [parent=#Armature] getCacheFrameRate 
-- @param self
-- @return unsigned int#unsigned int ret (return value: unsigned int)
        
--------------------------------
-- 
-- @function [parent=#Armature] getName 
-- @param self
-- @return string#string ret (return value: string)
        
--------------------------------
-- 
-- @function [parent=#Armature] dispose 
-- @param self
-- @return Armature#Armature self (return value: db.Armature)
        
--------------------------------
-- 
-- @function [parent=#Armature] addSlot 
-- @param self
-- @param #db.Slot value
-- @param #string boneName
-- @return Armature#Armature self (return value: db.Armature)
        
--------------------------------
-- 
-- @function [parent=#Armature] invalidUpdate 
-- @param self
-- @return Armature#Armature self (return value: db.Armature)
        
--------------------------------
-- 
-- @function [parent=#Armature] getBoneByDisplay 
-- @param self
-- @param #void display
-- @return Bone#Bone ret (return value: db.Bone)
        
--------------------------------
-- 
-- @function [parent=#Armature] setCacheFrameRate 
-- @param self
-- @param #unsigned int value
-- @return Armature#Armature self (return value: db.Armature)
        
--------------------------------
-- 
-- @function [parent=#Armature] removeSlot 
-- @param self
-- @param #db.Slot value
-- @return Armature#Armature self (return value: db.Armature)
        
--------------------------------
-- 
-- @function [parent=#Armature] addBone 
-- @param self
-- @param #db.Bone value
-- @param #string parentName
-- @return Armature#Armature self (return value: db.Armature)
        
--------------------------------
-- 
-- @function [parent=#Armature] getArmatureData 
-- @param self
-- @return ArmatureData#ArmatureData ret (return value: db.ArmatureData)
        
--------------------------------
-- 
-- @function [parent=#Armature] getClassTypeIndex 
-- @param self
-- @return unsigned int#unsigned int ret (return value: unsigned int)
        
--------------------------------
-- 
-- @function [parent=#Armature] getBone 
-- @param self
-- @param #string name
-- @return Bone#Bone ret (return value: db.Bone)
        
--------------------------------
-- 
-- @function [parent=#Armature] getAnimation 
-- @param self
-- @return Animation#Animation ret (return value: db.Animation)
        
--------------------------------
-- 
-- @function [parent=#Armature] getParent 
-- @param self
-- @return Slot#Slot ret (return value: db.Slot)
        
--------------------------------
-- 
-- @function [parent=#Armature] getSlotByDisplay 
-- @param self
-- @param #void display
-- @return Slot#Slot ret (return value: db.Slot)
        
--------------------------------
-- 
-- @function [parent=#Armature] removeBone 
-- @param self
-- @param #db.Bone value
-- @return Armature#Armature self (return value: db.Armature)
        
--------------------------------
-- 
-- @function [parent=#Armature] replaceTexture 
-- @param self
-- @param #void texture
-- @return Armature#Armature self (return value: db.Armature)
        
--------------------------------
-- 
-- @function [parent=#Armature] getTypeIndex 
-- @param self
-- @return unsigned int#unsigned int ret (return value: unsigned int)
        
--------------------------------
-- 
-- @function [parent=#Armature] advanceTime 
-- @param self
-- @param #float passedTime
-- @return Armature#Armature self (return value: db.Armature)
        
return nil
