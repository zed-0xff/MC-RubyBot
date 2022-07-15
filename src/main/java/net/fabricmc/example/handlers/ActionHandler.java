package net.fabricmc.example.handlers;

import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpHandler;
import java.io.IOException;
import java.io.OutputStream;

import net.minecraft.block.BlockState;
import net.minecraft.client.MinecraftClient;
import net.minecraft.client.option.KeyBinding;
import net.minecraft.entity.Entity;
import net.minecraft.entity.EntityType;
import net.minecraft.entity.LivingEntity;
import net.minecraft.entity.player.PlayerEntity;
import net.minecraft.state.property.BooleanProperty;
import net.minecraft.state.property.IntProperty;
import net.minecraft.state.property.Property;
import net.minecraft.util.Identifier;
import net.minecraft.util.hit.BlockHitResult;
import net.minecraft.util.hit.EntityHitResult;
import net.minecraft.util.hit.HitResult;
import net.minecraft.util.math.BlockPos;
import net.minecraft.util.math.Box;
import net.minecraft.util.math.MathHelper;
import net.minecraft.util.registry.Registry;
import net.minecraft.command.argument.EntityAnchorArgumentType.EntityAnchor;
import net.minecraft.util.math.Vec3d;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import org.apache.commons.lang3.time.StopWatch;

import java.io.UnsupportedEncodingException;
import java.io.InputStreamReader;
import java.util.List;

import java.lang.reflect.Type;
import com.google.gson.*;
import com.google.gson.reflect.TypeToken;

public class ActionHandler implements HttpHandler {
    public static final Logger LOGGER = LoggerFactory.getLogger("modid");
    private static MinecraftClient mc;

    private String body = new String();

    private static final GsonBuilder GSON = new GsonBuilder()
        .registerTypeAdapter(Vec3d.class, new Vec3dDeserializer())
        .registerTypeAdapter(Box.class, new BoxDeserializer())
        ;

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

    private class Action {
        public String command;
        public Vec3d target;
        public Box box;
        public int delay = 1000;

        public String toString() {
            String s = "Action:" + command;
            if( target != null )
                s = s + " target:" + target.toString();
            if( box != null )
                s = s + " box:" + box.toString();
            return s;
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
        PlayerEntity player = (PlayerEntity) mc.getCameraEntity();
        //Clone the loc to prevent applied changes to the input loc

        // Values of change in distance (make it relative)
        double dx = lookat.getX() - player.getX();
        double dy = lookat.getY() - player.getY();
        double dz = lookat.getZ() - player.getZ();

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
            double yaw = canonicalizeYaw(player.getYaw());

            // "2 -> 359" => "2 -> -1"
            if ( newYaw-yaw > 180 ) newYaw -= 360;
            // "359 -> 2" => "359 -> 362"
            if ( yaw-newYaw > 180 ) newYaw += 360;

            double pitch = player.getPitch();
            int nsteps = (int)Math.ceil(Math.abs(newYaw-yaw)/10);

            double dY = (newYaw-yaw)/nsteps;
            double dP = (newPitch-pitch)/nsteps;

            for (int i=0; i<(nsteps-1); i++) {
                yaw += dY;
                pitch += dP;
                player.setYaw((float)yaw);
                player.setPitch((float)pitch);
                try { Thread.sleep(delay); } catch (InterruptedException e) {}
            }
        }

        player.setYaw((float)newYaw);
        player.setPitch((float)newPitch);
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

    private int doAction(HttpExchange http) throws UnsupportedEncodingException {
        if ( !http.getRequestMethod().equals("POST") ) {
            body = "I want POST";
            return 400;
        }
        List<Action> script = GSON.create().fromJson(
                new InputStreamReader(http.getRequestBody(), "UTF-8"),
                new TypeToken<List<Action>>() {}.getType());
        PlayerEntity player = (PlayerEntity) mc.getCameraEntity();

        for( Action action : script ) {
            LOGGER.info(action.toString());
            if ( action.command.equals("lookAt") ) {
                lookAt(action.target, action.delay);
            } else if (action.command.equals("travel")) {
                player.travel(action.target);
            } else if (action.command.equals("blocks")) {
                // target is a "radius"
                BlockPos b1 = new BlockPos(action.box.minX, action.box.minY, action.box.minZ);
                BlockPos b2 = new BlockPos(action.box.maxX, action.box.maxY, action.box.maxZ);
                JsonArray arr = new JsonArray();
                for( BlockPos pos : BlockPos.iterate(b1, b2)) {
                    BlockState state = mc.world.getBlockState(pos);
                    JsonObject x = StatusHandler.serializeBlockState(state);
                    x.add("pos", StatusHandler.serializePos(pos));
                    arr.add(x);
                }
                body = arr.toString();
                return 200;
            } else if (action.command.equals("mine")) {
                mine(action.delay);
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
