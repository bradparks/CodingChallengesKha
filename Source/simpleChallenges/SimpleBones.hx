package simpleChallenges;

import utils.ZUIUtils;
import kext.g4basics.Camera3D;
import kha.Assets;
import kha.Color;
import kha.Image;
import kha.Framebuffer;
import kha.Shaders;
import kha.graphics4.VertexData;
import kha.math.Vector3;
import kha.math.FastVector3;

import kext.Application;
import kext.AppState;
import kext.g4basics.BasicMesh;
import kext.g4basics.SkeletalMesh;
import kext.g4basics.BasicPipeline;
import kext.g4basics.G4Constants;

import zui.Zui;
import zui.Id;

class SimpleBones extends AppState {
	private static inline var CANVAS_WIDTH:Int = 800;
	private static inline var CANVAS_HEIGHT:Int = 800;
	private static inline var NAME:String = "Simple Bones";
	
	private var basicPipeline:BasicPipeline;
	private var animatedPipeline:BasicPipeline;
	private var floor:BasicMesh;
	private var animatedMesh:SkeletalMesh;

	private var characterSpeed:Float = 10;
	private var characterPosition:Vector3;

	private var lookAtCharacter:Bool = true;
	private var cameraPosition:Vector3;
	private var cameraAngle:Float = 0;

	private var rotateArroundChacter:Bool = false;
	private var cameraRotationSpeed:Float = 0.2;
	private var cameraRotationRadius:Float = 10;

	private var camera:Camera3D;

	public static function initApplication() {
		return new Application(
			{title: SimpleBones.NAME, width: SimpleBones.CANVAS_WIDTH, height: SimpleBones.CANVAS_HEIGHT},
			{initState: SimpleBones, defaultFontName: "KenPixel"}
		);
	}

	public function new() {
		super();

		camera = new Camera3D();
		Application.mainCamera = camera;
		cameraPosition = new Vector3(0, -10, 10);
		characterPosition = new Vector3(0, 0, 0);

		basicPipeline = new BasicPipeline(Shaders.textured_vert, Shaders.striped_frag);
		basicPipeline.compile();

		animatedPipeline = new BasicPipeline(Shaders.texturedBones_vert, Shaders.textured_frag);
		animatedPipeline.addVertexData(G4Constants.VERTEX_DATA_JOINT_INDEX, VertexData.Float4);
		animatedPipeline.addVertexData(G4Constants.VERTEX_DATA_JOINT_WEIGHT, VertexData.Float4);
		animatedPipeline.compile();

		floor = BasicMesh.createQuadMesh(new Vector3(-1, -1, 0), new Vector3(1, 1, 0), basicPipeline, Color.Green);
		floor.transform.setScale(new Vector3(10, 10, 1));
		
		animatedMesh = SkeletalMesh.getOGEXAnimatedMesh(Assets.blobs.CharacterRunning_ogex, animatedPipeline, Color.White);
		animatedMesh.texture = Assets.images.CharacterTexture;
		animatedMesh.transform.scaleTransform(new Vector3(.7, .7, .7));
	}

	override public function update(delta:Float) {
		handleCharacterMovement(delta);
		if(rotateArroundChacter) {
			rotateCamera(delta);
		}

		animatedMesh.update(delta);
	}

	private function handleCharacterMovement(delta:Float) {
		if(Application.keyboard.keyDown(kha.input.KeyCode.A)) {
			characterPosition.x += delta * characterSpeed;
			animatedMesh.transform.rotationY = Math.PI * 0.5;
		} else if(Application.keyboard.keyDown(kha.input.KeyCode.D)) {
			characterPosition.x -= delta * characterSpeed;
			animatedMesh.transform.rotationY = Math.PI * 1.5;
		}
		if(Application.keyboard.keyDown(kha.input.KeyCode.W)) {
			characterPosition.y += delta * characterSpeed;
			animatedMesh.transform.rotationY = Math.PI;
		} else if(Application.keyboard.keyDown(kha.input.KeyCode.S)) {
			characterPosition.y -= delta * characterSpeed;
			animatedMesh.transform.rotationY = 0;
		}
	}

	private function rotateCamera(delta:Float) {
		cameraAngle += delta * cameraRotationSpeed * Math.PI * 2;

		cameraPosition.x = characterPosition.x + Math.sin(cameraAngle) * cameraRotationRadius;
		cameraPosition.y = characterPosition.y + Math.cos(cameraAngle) * cameraRotationRadius;
	}

	override public function render(backbuffer:Image) {
		camera.transform.setPosition(cameraPosition);
		animatedMesh.transform.setPosition(characterPosition);
		var fastCharacterPosition:FastVector3 = new FastVector3(characterPosition.x, characterPosition.y, characterPosition.z);
		
		camera.lookAt(
			lookAtCharacter ? characterPosition.fast() : new FastVector3(0, 0, 0),
			new FastVector3(0, 0, -1)
		);
		
		backbuffer.g4.begin();
		backbuffer.g4.clear(Color.Black, Math.POSITIVE_INFINITY);

		animatedMesh.render(backbuffer);
		
		floor.render(backbuffer);

		backbuffer.g4.end();
	}

	override public function renderFramebuffer(framebuffer:Framebuffer) {
		ui.begin(framebuffer.g2);
		if(ui.window(Id.handle(), 0, 0, 400, 800)) {
			uiToggle = ui.check(Id.handle({selected: true}), "UI On/Off");
			if(uiToggle) {
				lookAtCharacter = ui.check(Id.handle({selected: lookAtCharacter}), "Look At Character");

				characterSpeed = ui.slider(Id.handle({value: characterSpeed}), "Character Speed", 0, 100, true, 10, true);
				
				rotateArroundChacter = ui.check(Id.handle({selected: rotateArroundChacter}), "Rotate Arround Chacter");
				if(rotateArroundChacter) {
					cameraRotationRadius = ui.slider(Id.handle({value: cameraRotationRadius}), "Camera Rotation Radius", 0, 100, true, 10, true);
					cameraRotationSpeed = ui.slider(Id.handle({value: cameraRotationSpeed}), "Camera Rotation Speed", -25, 25, true, 10, true);
					cameraPosition.z = ui.slider(Id.handle({value: cameraPosition.z}), "Camera Position Z", -25, 25, true, 10, true);
				} else {
					ZUIUtils.vector3Sliders(ui, Id.handle(), cameraPosition, "Camera Position", -25, 25, 10);
				}

				animatedMesh.animationSpeed = ui.slider(Id.handle({value: animatedMesh.animationSpeed}), "Animation Speed", -10, 10, true, 10, true);
			}
		}
		ui.end();
	}

}