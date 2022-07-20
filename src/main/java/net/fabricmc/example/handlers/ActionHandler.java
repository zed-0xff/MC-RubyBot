package net.fabricmc.example.handlers;

import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpHandler;
import java.io.IOException;
import java.io.OutputStream;

import net.minecraft.sound.SoundEvents;
import net.minecraft.block.AirBlock;
import net.minecraft.block.BlockState;
import net.minecraft.client.MinecraftClient;
import net.minecraft.client.option.GameOptions;
import net.minecraft.client.option.KeyBinding;
import net.minecraft.client.util.InputUtil;
import net.minecraft.command.argument.EntityAnchorArgumentType.EntityAnchor;
import net.minecraft.entity.Entity;
import net.minecraft.entity.EntityType;
import net.minecraft.entity.LivingEntity;
import net.minecraft.entity.mob.PathAwareEntity;
import net.minecraft.entity.player.PlayerEntity;
import net.minecraft.sound.SoundEvent;
import net.minecraft.client.sound.PositionedSoundInstance;
import net.minecraft.state.property.BooleanProperty;
import net.minecraft.state.property.IntProperty;
import net.minecraft.state.property.Property;
import net.minecraft.text.Text;
import net.minecraft.util.Identifier;
import net.minecraft.util.hit.BlockHitResult;
import net.minecraft.util.hit.EntityHitResult;
import net.minecraft.util.hit.HitResult;
import net.minecraft.util.math.BlockPos;
import net.minecraft.util.math.Box;
import net.minecraft.util.math.MathHelper;
import net.minecraft.util.math.Vec3d;
import net.minecraft.util.registry.Registry;
import net.minecraft.util.registry.RegistryEntry;
import net.minecraft.util.math.random.Random;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import org.apache.commons.lang3.time.StopWatch;

import java.io.UnsupportedEncodingException;
import java.io.InputStreamReader;
import java.util.List;
import java.util.ArrayList;

import java.lang.reflect.Type;
import com.google.gson.*;
import com.google.gson.reflect.TypeToken;

import net.fabricmc.example.ExampleMod;
import net.fabricmc.example.utils.AI;
import net.fabricmc.example.utils.Serializer;
import net.minecraft.entity.mob.ZombieEntity;
import net.minecraft.entity.passive.CatEntity;

public class ActionHandler implements HttpHandler {
    public static final Logger LOGGER = LoggerFactory.getLogger("modid");
    private static MinecraftClient mc;

    public static String log = new String();

    private String body = new String();

    private static final Gson GSON = new GsonBuilder()
        .registerTypeAdapter(Vec3d.class, new Vec3dDeserializer())
        .registerTypeAdapter(Box.class, new BoxDeserializer())
        .create();

    public static class Vec3dDeserializer implements JsonDeserializer<Vec3d> {
        @Override
        public Vec3d deserialize(JsonElement json, Type typeOfT, JsonDeserializationContext context) throws JsonParseException {
            JsonObject jsonObject = json.getAsJsonObject();
            return new Vec3d(
                    jsonObject.get("x").getAsDouble(),
                    jsonObject.get("y").getAsDouble(),
                    jsonObject.get("z").getAsDouble()
                    );
        }
    }

    public static class BoxDeserializer implements JsonDeserializer<Box> {
        @Override
        public Box deserialize(JsonElement json, Type typeOfT, JsonDeserializationContext context) throws JsonParseException {
            JsonObject jsonObject = json.getAsJsonObject();
            return new Box(
                    jsonObject.get("minX").getAsDouble(),
                    jsonObject.get("minY").getAsDouble(),
                    jsonObject.get("minZ").getAsDouble(),
                    jsonObject.get("maxX").getAsDouble(),
                    jsonObject.get("maxY").getAsDouble(),
                    jsonObject.get("maxZ").getAsDouble()
                    );
        }
    }

	public ActionHandler(MinecraftClient mc) {
	    ActionHandler.mc = mc;
	}

    private static double canonicalizeYaw(double yaw) {
        // **facepalm**
        while( yaw < 0 )   yaw += 360;
        while( yaw > 360 ) yaw -= 360;
        return yaw;
    }

    // https://bukkit.org/threads/lookat-and-move-functions.26768/
    public static void lookAt(Vec3d lookat, int delay) {
        //Clone the loc to prevent applied changes to the input loc

        // Values of change in distance (make it relative)
        double dx = lookat.getX() - mc.player.getX();
        double dy = lookat.getY() - mc.player.getY();
        double dz = lookat.getZ() - mc.player.getZ();

        double newPitch = 0;
        double newYaw = 0;

        // Set newYaw
        if (dx != 0) {
            // Set newYaw start value based on dx
            if (dx < 0) {
                newYaw = 1.5 * Math.PI;
            } else {
                newYaw = 0.5 * Math.PI;
            }
            newYaw -= Math.atan(dz / dx);
        } else if (dz < 0) {
            newYaw = Math.PI;
        }

        // Get the distance from dx/dz
        double dxz = Math.sqrt(Math.pow(dx, 2) + Math.pow(dz, 2));

        // Set newPitch
        newPitch = -Math.atan(dy / dxz);

//        LOGGER.info("[d] new newYaw: " + newYaw);
//        LOGGER.info("[d] new newPitch: " + newPitch);

        // Set values, convert to degrees (invert the newYaw since Bukkit uses a different newYaw dimension format)
        newYaw = -newYaw * 180 / Math.PI;
        newPitch = newPitch * 180 / Math.PI;

        if ( delay > 0 ) {
            newYaw = canonicalizeYaw(newYaw);
            double yaw = canonicalizeYaw(mc.player.getYaw());

            // "2 -> 359" => "2 -> -1"
            if ( newYaw-yaw > 180 ) newYaw -= 360;
            // "359 -> 2" => "359 -> 362"
            if ( yaw-newYaw > 180 ) newYaw += 360;

            double pitch = mc.player.getPitch();
            int nsteps = (int)Math.ceil(Math.abs(newYaw-yaw)/10);

            double dY = (newYaw-yaw)/nsteps;
            double dP = (newPitch-pitch)/nsteps;

            for (int i=0; i<(nsteps-1); i++) {
                yaw += dY;
                pitch += dP;
                mc.player.setYaw((float)yaw);
                mc.player.setPitch((float)pitch);
                try { Thread.sleep(delay); } catch (InterruptedException e) {}
            }
        }

        mc.player.setYaw((float)newYaw);
        mc.player.setPitch((float)newPitch);
    }

    private void mine(int maxDelay) {
        HitResult target = mc.crosshairTarget;
        if (target instanceof BlockHitResult && mc.interactionManager != null) {
            BlockPos pos = ((BlockHitResult) target).getBlockPos();
            BlockState state = mc.world.getBlockState(pos);
            KeyBinding.setKeyPressed(mc.options.attackKey.getDefaultKey(), true);

            int delay = 0;
            while( delay < maxDelay && mc.world.getBlockState(pos).equals(state) ) {
                try { Thread.sleep(10); } catch (InterruptedException e) {}
                delay += 10;
            }
            KeyBinding.setKeyPressed(mc.options.attackKey.getDefaultKey(), false);
        }
    }

    // negative delay => release key
    // zero delay     => press key
    // positive delay => press, wait, release
    private void pressKey(String keyName, int delay) {
        InputUtil.Key key = InputUtil.fromTranslationKey(keyName);
        if ( delay > 0 ) {
            KeyBinding.setKeyPressed(key, true);
            try { Thread.sleep(delay); } catch (InterruptedException e) {}
            KeyBinding.setKeyPressed(key, false);
        } else if ( delay == 0 ) {
            KeyBinding.setKeyPressed(key, true);
        } else {
            KeyBinding.setKeyPressed(key, false);
        }
    }

    private boolean ai(Vec3d target) {
////        ZombieEntity z = new ZombieEntity(mc.world);
//        CatEntity cat = new CatEntity(EntityType.CAT, mc.world);
////        cat.initialize(mc.world, null, null, null, null);
//        cat.setPosition(player.getPos());
//        AI ai = new AI(cat, mc.world);
//        LOGGER.info("[d] ai pos: " + ai.getPos().toString());
//        for( int i=-3; i<3; i++ ) {
//            for( int j=-3; j<3; j++ ) {
//                Vec3d t2 = new Vec3d(target.x+i, target.y, target.z+j);
//                LOGGER.info("[d] " + ai.canPathDirectlyThrough(target, t2));
//                LOGGER.info("[d] " + ai.findPathTo(new BlockPos(t2), 5));
//            }
//        }
//        return ai.canPathDirectlyThrough(player.getPos(), target);
        return false;
    }

    private class Action {
        public String command;
        public String stringArg;
        public Vec3d target;
        public Box box;
        public int delay = 1000;
        public boolean boolArg = false;
        public float floatArg;
        public int intArg;

        public String toString() {
            String s = "Action:" + command;
            if( target != null )
                s = s + " target:" + target.toString();
            if( box != null )
                s = s + " box:" + box.toString();
            return s;
        }
    }

    private int doAction(HttpExchange http) throws UnsupportedEncodingException {
        if ( !http.getRequestMethod().equals("POST") ) {
            body = "I want POST";
            return 400;
        }
        List<Action> script = GSON.fromJson(
                new InputStreamReader(http.getRequestBody(), "UTF-8"),
                new TypeToken<List<Action>>() {}.getType());

        for( Action action : script ) {
            //LOGGER.info(action.toString());
            if ( action.command.equals("lookAt") ) {
                lookAt(action.target, action.delay);
                JsonObject obj = StatusHandler.serializePlayerLookingAt(mc.crosshairTarget);
                body = obj.toString();
                return 200;
            } else if (action.command.equals("travel")) {
                mc.player.travel(action.target);
            } else if (action.command.equals("blocks")) {
                BlockPos b1 = new BlockPos(action.box.minX, action.box.minY, action.box.minZ);
                BlockPos b2 = new BlockPos(action.box.maxX, action.box.maxY, action.box.maxZ);
                JsonArray arr = new JsonArray();
                for( BlockPos pos : BlockPos.iterate(b1, b2)) {
                    BlockState state = mc.world.getBlockState(pos);
                    if ( state.getBlock() instanceof AirBlock )
                        continue;
                    JsonObject x = StatusHandler.serializeBlockState(state);
                    x.add("pos", Serializer.toJsonTree(pos));
                    arr.add(x);
                }
                body = arr.toString();
                return 200;
            } else if (action.command.equals("blocksRelative")) {
                BlockPos b1 = new BlockPos(action.box.minX, action.box.minY, action.box.minZ);
                BlockPos b2 = new BlockPos(action.box.maxX, action.box.maxY, action.box.maxZ);
                JsonArray arr = new JsonArray();
                for( BlockPos pos : BlockPos.iterate(b1, b2)) {
                    BlockState state = mc.world.getBlockState(pos);
                    if ( state.getBlock() instanceof AirBlock )
                        continue;
                    JsonObject x = StatusHandler.serializeBlockState(state);
                    x.add("pos", Serializer.toJsonTree(pos));
                    arr.add(x);
                }
                body = arr.toString();
                return 200;
            } else if (action.command.equals("mine")) {
                mine(action.delay);
            } else if (action.command.equals("log")) {
                body = log;
                log = new String();
                return 200;
            } else if (action.command.equals("key")) {
                pressKey(action.stringArg, action.delay);
            } else if (action.command.equals("ai")) {
                body = ai(action.target) ? "true" : "false";
                return 200;
            } else if (action.command.equals("say")) {
                mc.player.sendMessage(Text.literal(action.stringArg));
            } else if (action.command.equals("chat")) {
                mc.player.sendChatMessage(action.stringArg);
            } else if (action.command.equals("setAutoJump")) {
                mc.options.getAutoJump().setValue(action.boolArg);
            } else if (action.command.equals("playSound")) {
                SoundEvent event = Registry.SOUND_EVENT.get(new Identifier(action.stringArg));
                if ( event == null ) {
                    event = Registry.SOUND_EVENT.getRandom(Random.create())
                        .map(RegistryEntry::value)
                        .orElse(SoundEvents.ENTITY_GENERIC_EXPLODE);
                    LOGGER.info("[?] no sound with id '" + action.stringArg + "', playing '" + event.getId() + "' instead");
                }
                mc.getSoundManager().play(PositionedSoundInstance.master(event, 1.0F, action.floatArg));
            } else if (action.command.equals("swapSlotWithHotbar")) {
                mc.player.getInventory().swapSlotWithHotbar(action.intArg);
            } else if (action.command.equals("selectSlot")) {
                mc.player.getInventory().selectedSlot = action.intArg;
            } else if (action.command.equals("sleep")) {
                try { Thread.sleep(action.delay); } catch (InterruptedException e) {}
            } else if (action.command.equals("registerCommand")) {
                ExampleMod.registerCommand(action.stringArg);
            } else if (action.command.equals("getMobs")) {
                Vec3d pos = mc.player.getPos();
                List<PathAwareEntity> l = mc.world.getEntitiesByClass(PathAwareEntity.class, action.box, LivingEntity::isAlive);
                JsonObject obj = new JsonObject();
                JsonArray mobs = new JsonArray();
                for ( PathAwareEntity e : l ) {
                    mobs.add(StatusHandler.serializeEntity(e));
                }
                obj.add("mobs", mobs);
                obj.add("looking_at", StatusHandler.serializePlayerLookingAt(mc.crosshairTarget));
                body = obj.toString();
                return 200;
            } else {
                LOGGER.error("[?] invalid action: " + action.command);
            }
        }

        return 204;
    }

	@Override
	public void handle(HttpExchange http) throws IOException {
        StopWatch stopwatch = StopWatch.createStarted();
        try {
            int status;

            try {
                status = doAction(http);
            } catch (Exception e) {
                body = e.toString();
                status = 500;
            }

            byte[] bytes = body.getBytes();
            http.getResponseHeaders().set("X-Processing-Time", Long.toString(stopwatch.getTime()));
//            http.getResponseHeaders().set("Connection", "close");
            http.sendResponseHeaders(status, bytes.length);

            if ( status != 204 ) {
                OutputStream os = http.getResponseBody();
                os.write(bytes);
                os.flush();
                os.close();
            }
        } catch (Exception e) {
            LOGGER.error(e.toString());
        }
	}
}
