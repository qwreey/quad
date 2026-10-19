--!strict
-- [2026-10-19 Studio copy of harness/compare/mapsize2/cat3d.luau — same lines; requires rewritten to the Studio tree (probe.project.json). CLI results: that file.]
-- [2026-10-19 M4] category map: 84 creatable 3D/world classes (PVInstance/Constraint/JointInstance/Light/Attachment/... + effects), alphabetical literal-union bound
local L = require("./Lib2")
type Map = { Actor: Actor, AlignOrientation: AlignOrientation, AlignPosition: AlignPosition, AngularVelocity: AngularVelocity, AnimationConstraint: AnimationConstraint, Attachment: Attachment, BallSocketConstraint: BallSocketConstraint, Beam: Beam, BlockMesh: BlockMesh, BodyAngularVelocity: BodyAngularVelocity, BodyForce: BodyForce, BodyGyro: BodyGyro, BodyPosition: BodyPosition, BodyThrust: BodyThrust, BodyVelocity: BodyVelocity, Bone: Bone, Camera: Camera, ClickDetector: ClickDetector, CornerWedgePart: CornerWedgePart, CylinderMesh: CylinderMesh, CylindricalConstraint: CylindricalConstraint, Decal: Decal, Explosion: Explosion, FileMesh: FileMesh, Fire: Fire, Flag: Flag, FlagStand: FlagStand, Glue: Glue, Highlight: Highlight, HingeConstraint: HingeConstraint, HopperBin: HopperBin, IntersectOperation: IntersectOperation, LineForce: LineForce, LinearVelocity: LinearVelocity, ManualGlue: ManualGlue, ManualWeld: ManualWeld, MeshPart: MeshPart, Model: Model, Motor: Motor, Motor6D: Motor6D, NegateOperation: NegateOperation, Part: Part, PartOperation: PartOperation, ParticleEmitter: ParticleEmitter, Plane: Plane, PlaneConstraint: PlaneConstraint, PointLight: PointLight, PrismaticConstraint: PrismaticConstraint, ProceduralModel: ProceduralModel, ProximityPrompt: ProximityPrompt, RigidConstraint: RigidConstraint, RocketPropulsion: RocketPropulsion, RodConstraint: RodConstraint, RopeConstraint: RopeConstraint, Rotate: Rotate, RotateP: RotateP, RotateV: RotateV, Seat: Seat, SkateboardPlatform: SkateboardPlatform, Smoke: Smoke, Snap: Snap, Sound: Sound, Sparkles: Sparkles, SpawnLocation: SpawnLocation, SpecialMesh: SpecialMesh, SpotLight: SpotLight, SpringConstraint: SpringConstraint, SurfaceAppearance: SurfaceAppearance, SurfaceLight: SurfaceLight, Texture: Texture, Tool: Tool, Torque: Torque, TorsionSpringConstraint: TorsionSpringConstraint, Trail: Trail, TrussPart: TrussPart, UnionOperation: UnionOperation, UniversalConstraint: UniversalConstraint, VectorForce: VectorForce, VehicleSeat: VehicleSeat, VelocityMotor: VelocityMotor, ViewportCamera: ViewportCamera, WedgePart: WedgePart, Weld: Weld, WorldModel: WorldModel }
type Names = "Actor" | "AlignOrientation" | "AlignPosition" | "AngularVelocity" | "AnimationConstraint" | "Attachment" | "BallSocketConstraint" | "Beam" | "BlockMesh" | "BodyAngularVelocity" | "BodyForce" | "BodyGyro" | "BodyPosition" | "BodyThrust" | "BodyVelocity" | "Bone" | "Camera" | "ClickDetector" | "CornerWedgePart" | "CylinderMesh" | "CylindricalConstraint" | "Decal" | "Explosion" | "FileMesh" | "Fire" | "Flag" | "FlagStand" | "Glue" | "Highlight" | "HingeConstraint" | "HopperBin" | "IntersectOperation" | "LineForce" | "LinearVelocity" | "ManualGlue" | "ManualWeld" | "MeshPart" | "Model" | "Motor" | "Motor6D" | "NegateOperation" | "Part" | "PartOperation" | "ParticleEmitter" | "Plane" | "PlaneConstraint" | "PointLight" | "PrismaticConstraint" | "ProceduralModel" | "ProximityPrompt" | "RigidConstraint" | "RocketPropulsion" | "RodConstraint" | "RopeConstraint" | "Rotate" | "RotateP" | "RotateV" | "Seat" | "SkateboardPlatform" | "Smoke" | "Snap" | "Sound" | "Sparkles" | "SpawnLocation" | "SpecialMesh" | "SpotLight" | "SpringConstraint" | "SurfaceAppearance" | "SurfaceLight" | "Texture" | "Tool" | "Torque" | "TorsionSpringConstraint" | "Trail" | "TrussPart" | "UnionOperation" | "UniversalConstraint" | "VectorForce" | "VehicleSeat" | "VelocityMotor" | "ViewportCamera" | "WedgePart" | "Weld" | "WorldModel"
local E = (nil :: any) :: <K>(name: K & Names) -> (L.Props<index<Map, K>>) -> index<Map, K>
local PartC = E "Part" -- pos 42
local MeshPartC = E "MeshPart" -- pos 37
local SpawnLocationC = E "SpawnLocation" -- pos 64
local SeatC = E "Seat" -- pos 58
local VehicleSeatC = E "VehicleSeat" -- pos 79
local TrussPartC = E "TrussPart" -- pos 75
local WedgePartC = E "WedgePart" -- pos 82
local ParticleEmitterC = E "ParticleEmitter" -- pos 44
local BeamC = E "Beam" -- pos 8
local TrailC = E "Trail" -- pos 74
local ToolC = E "Tool" -- pos 71
local SoundC = E "Sound" -- pos 62
local ModelC = E "Model" -- pos 38
local AttachmentC = E "Attachment" -- pos 6
local PointLightC = E "PointLight" -- pos 47
local ExplosionC = E "Explosion" -- pos 23
local UnionOperationC = E "UnionOperation" -- pos 76
local bad1 = PartC { Anchored = 5 } -- NEG
local bad2 = E "Frame" -- NEG not in this category
return { PartC, MeshPartC, SpawnLocationC, SeatC, VehicleSeatC, TrussPartC, WedgePartC, ParticleEmitterC, BeamC, TrailC, ToolC, SoundC, ModelC, AttachmentC, PointLightC, ExplosionC, UnionOperationC, bad1, bad2 }
