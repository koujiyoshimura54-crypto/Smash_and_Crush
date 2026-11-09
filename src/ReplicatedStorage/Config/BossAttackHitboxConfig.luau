-- Legacy Stage1 view. All live stages use BossBehaviorConfig directly.
return table.freeze({DepthScale=require(script.Parent.BossBehaviorConfig).Get(1,1).DepthScale})
