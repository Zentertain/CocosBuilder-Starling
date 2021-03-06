// =================================================================================================
//
//	Starling Framework Extension
//	Copyright 2014 nkligang(nkligang@163.com). All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.cocosbuilder
{
	import flash.geom.Point;
	import flash.utils.getDefinitionByName;

	public class CCBFile
	{
		public var mJSControlled:Boolean = false;
		public var mAutoPlaySequenceId:int = -1;
		public var mSequences:Vector.<CCBSequence>;
		public var mRootNode:CCNodeProperty;
		
		public static const CCBNodeClassName_CCLayer:String              = "CCLayer";
		public static const CCBNodeClassName_CCLayerColor:String         = "CCLayerColor";
		public static const CCBNodeClassName_CCLayerGradient:String      = "CCLayerGradient";
		public static const CCBNodeClassName_CCScrollView:String         = "CCScrollView";
		public static const CCBNodeClassName_CCNode:String               = "CCNode";
		public static const CCBNodeClassName_CCSprite:String             = "CCSprite";
		public static const CCBNodeClassName_CCLabelTTF:String           = "CCLabelTTF";
		public static const CCBNodeClassName_CCLabelBMFont:String        = "CCLabelBMFont";
		public static const CCBNodeClassName_CCScale9Sprite:String       = "CCScale9Sprite";
		public static const CCBNodeClassName_CCControlButton:String      = "CCControlButton";
		public static const CCBNodeClassName_CCParticleSystemQuad:String = "CCParticleSystemQuad";
		public static const CCBNodeClassName_CCBFile:String              = "CCBFile";

		public static var sCustomClassPrefix:String;

		/** helper objects */
		
		public function CCBFile()
		{
		}
		
		private function createDisplayNodeGraph(parentObject:CCNode, nodeInfo:CCNodeProperty):CCNode
		{
			var nodeObject:CCNode = null;
			if (nodeInfo.className == CCBNodeClassName_CCBFile)
			{
				var ccb:CCBFileRef = nodeInfo.getProperty(CCNodeProperty.CCBNodePropertyCCBFile) as CCBFileRef;
				if (ccb != null)
				{
					var ccbFile:CCBFile = ccb.getCCB();
					if (ccbFile != null)
					{
						var ccbAnim:CCNode = ccbFile.createNodeGraph();
						
						ccbAnim.anchorPoint = nodeInfo.getAnchorPoint();
						nodeObject = ccbAnim;
					}
					else
					{
						trace("createDisplayNodeGraph: ccb file is not prepared.");
					}
				}
				else
				{
					trace("createDisplayNodeGraph: ccb node without ccb file referenced.");
				}					
			}
			else if (nodeInfo.className == CCBNodeClassName_CCSprite)
			{
				nodeObject = CCSprite.createWithNodeProperty(nodeInfo);
			}
			else if (nodeInfo.className == CCBNodeClassName_CCScale9Sprite)
			{
				nodeObject = CCScale9Sprite.createWithNodeProperty(nodeInfo);
			}
			else if (nodeInfo.className == CCBNodeClassName_CCLabelTTF)
			{
				nodeObject = CCLabelTTF.createWithNodeProperty(nodeInfo);
			}
			else if (nodeInfo.className == CCBNodeClassName_CCLabelBMFont)
			{
				nodeObject = CCLabelBMFont.createWithNodeProperty(nodeInfo);
			}
			else if (nodeInfo.className == CCBNodeClassName_CCNode)
			{
				nodeObject = CCNode.createWithNodeProperty(nodeInfo);
			}
			else if (nodeInfo.className == CCBNodeClassName_CCLayer)
			{
				nodeObject = CCLayer.createWithNodeProperty(nodeInfo);
			}
			else if (nodeInfo.className == CCBNodeClassName_CCLayerColor)
			{
				nodeObject = CCLayerColor.createWithNodeProperty(nodeInfo);
			}
			else if (nodeInfo.className == CCBNodeClassName_CCLayerGradient)
			{
				nodeObject = CCLayerGradient.createWithNodeProperty(nodeInfo);
			}
			else if (nodeInfo.className == CCBNodeClassName_CCScrollView)
			{
				nodeObject = CCScrollView.createWithNodeProperty(nodeInfo);
			}
			else if (nodeInfo.className == CCBNodeClassName_CCControlButton)
			{
				nodeObject = CCControlButton.createWithNodeProperty(nodeInfo);
			}
			else if (nodeInfo.className == CCBNodeClassName_CCParticleSystemQuad)
			{
				nodeObject = CCParticleSystemQuad.createWithNodeProperty(nodeInfo);
			}
			else
			{
				try
				{
					var customClassRef:Class = getDefinitionByName(sCustomClassPrefix + nodeInfo.className) as Class;
					nodeObject = new customClassRef() as CCNode;
					nodeObject.initWithNodeProperty(nodeInfo);
				}
				catch(error:ReferenceError)
				{
					throw new Error("[CCBFile] createDisplayNodeGraph: not implement class: '" + sCustomClassPrefix + nodeInfo.className + "'");
				}
			}
			// set target
			nodeObject.nodeProperty = nodeInfo;
				
			var memberVarAssignmentName:String = nodeInfo.getProperty(CCNodeProperty.CCBNodePropertyMemberVarAssignmentName) as String;
			if (memberVarAssignmentName != null)
				nodeObject.name = memberVarAssignmentName;

			// calculate local position
			var localPosition:Point = nodeInfo.getPosition(parentObject, nodeObject);
			nodeObject.x =  localPosition.x;
			nodeObject.y = -localPosition.y;

			// calculate local content size
			var localContentSize:Point = new Point;
			var contentSizeObj:Object = nodeInfo.getProperty(CCNodeProperty.CCBNodePropertyContentSize);
			var contentSize:CCTypeSize = null;
			if (contentSizeObj != null) {
				contentSize = contentSizeObj as CCTypeSize;
				CCNodeProperty.getContentSize(contentSize, parentObject, nodeObject, localContentSize);
				nodeObject.contentSizeX = localContentSize.x;
				nodeObject.contentSizeY = localContentSize.y;
			}

			// calculate local scale
			var localScale:Point = nodeInfo.getScale(parentObject, nodeObject);
			nodeObject.scaleX = localScale.x;
			nodeObject.scaleY = localScale.y;

			nodeObject.visible = nodeInfo.isVisible();
			
			var mChildren:Vector.<CCNodeProperty> = nodeInfo.getChildren();
			var numChildren:int = mChildren.length;
			for (var i:int=0; i<numChildren; ++i)
			{
				var childNodeInfo:CCNodeProperty = mChildren[i];
				var childNodeObject:CCNode = createDisplayNodeGraph(nodeObject, childNodeInfo);
				nodeObject.addChild(childNodeObject);
				// 这里为什么要额外添加一个offsetY呢？因为Starling的坐标系中(0,0)是左上角；而Cocos2d的坐标系中
				// (0,0)是左下角
				childNodeObject.offsetY += nodeObject.contentSizeY;
			}

			return nodeObject;
		}
		
		public function createNodeGraph():CCNode
		{
			// 递归创建节点
			var node:CCNode = createDisplayNodeGraph(null, mRootNode);
			var actionManager:CCBAnimationManager = new CCBAnimationManager(this, node);
			node.animationManager = actionManager;
			
			if (mAutoPlaySequenceId >= 0)
				actionManager.startAnimationByIndex(mAutoPlaySequenceId, true);
			return node;
		}
		
		public function getSequenceIndexByName(seqName:String):int
		{
			var numSequence:int = mSequences.length;
			for (var i:int = 0; i < numSequence; ++i) {
				var sequence:CCBSequence = mSequences[i];
				if (sequence.name == seqName)
					return i;
			}
			return -1;
		}
		
		public function getSequenceByName(seqName:String):CCBSequence
		{
			var numSequence:int = mSequences.length;
			for (var i:int = 0; i < numSequence; ++i) {
				var sequence:CCBSequence = mSequences[i];
				if (sequence.name == seqName)
					return sequence;
			}
			return null;
		}
		
		public function getSequenceByIndex(idx:uint):CCBSequence
		{
			return mSequences[idx];
		}
		
		public function getSequenceCount():int { return mSequences.length; }
		
		public static function get CustomClassPrefix():String { return sCustomClassPrefix; }
		public static function set CustomClassPrefix(value:String):void { sCustomClassPrefix = value; }
	}
}
