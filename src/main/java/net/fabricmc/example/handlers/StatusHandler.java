package net.fabricmc.example.handlers;

import net.fabricmc.example.OpenNbtCompound;
import net.fabricmc.example.utils.Serializer;
import net.fabricmc.example.utils.StatusBarTracker;
import net.fabricmc.example.utils.XPInformation;
import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpHandler;
import java.io.IOException;
import java.io.OutputStream;
import java.io.ByteArrayOutputStream;
import java.io.DataOutputStream;
import java.io.FileOutputStream;
import java.util.Map;

import net.minecraft.block.BlockState;
import net.minecraft.client.MinecraftClient;
import net.minecraft.entity.Entity;
import net.minecraft.entity.EntityType;
import net.minecraft.entity.LivingEntity;
import net.minecraft.entity.mob.MobEntity;
import net.minecraft.entity.player.PlayerEntity;
import net.minecraft.entity.mob.HostileEntity;
import net.minecraft.state.property.BooleanProperty;
import net.minecraft.state.property.IntProperty;
import net.minecraft.state.property.Property;
import net.minecraft.util.Identifier;
import net.minecraft.util.hit.BlockHitResult;
import net.minecraft.util.hit.EntityHitResult;
import net.minecraft.util.hit.HitResult;
import net.minecraft.util.math.BlockPos;
import net.minecraft.util.math.MathHelper;
import net.minecraft.util.registry.Registry;
import net.minecraft.util.math.Vec3d;
import net.minecraft.nbt.NbtCompound;
import net.minecraft.nbt.NbtElement;

import com.google.gson.JsonObject;
import com.google.gson.Gson;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import org.apache.commons.lang3.time.StopWatch;
import java.util.UUID;

public class StatusHandler implements HttpHandler {
    public static final Logger LOGGER = LoggerFactory.getLogger("modid");
    private static MinecraftClient mc;
    private static final Gson GSON = new Gson();
    public static Locraw locraw;
    public static final StatusBarTracker statusBarTracker = new StatusBarTracker();

	public StatusHandler(MinecraftClient mc) {
	    StatusHandler.mc = mc;
	}

    // {"server":"mini31CG","gametype":"SKYBLOCK","mode":"foraging_1","map":"The Park"}
    public class Locraw {
        public String server;
        String gametype;
        String mode;
        String map;
    }

    public static void handleMessage(int type, String msg) {
        if (msg.startsWith("{") && msg.endsWith("}")) {
            setLocraw(msg);
        } else if (type == 2) {
            statusBarTracker.update(msg, false);
            XPInformation.getInstance().onChatReceived(msg);
        }
    }

    public static void setLocraw(String msg) {
        Locraw l = GSON.fromJson(msg, Locraw.class);
        if ( l.server != null || l.gametype != null || l.mode != null || l.map != null )
            locraw = l;
    }

    private static double getSpeed(Entity entity) {
        double dx = entity.getX() - entity.lastRenderX;
        double dy = entity.getY() - entity.lastRenderY;
        double dz = entity.getZ() - entity.lastRenderZ;
        double dist = Math.sqrt(dx * dx + dy * dy + dz * dz);
        return dist * 20;
    }

    private String getBiomeId(Vec3d pos) {
        return mc.world.getRegistryManager().
            get(Registry.BIOME_KEY).
            getId(mc.world.getBiome(new BlockPos(pos)).value()).
            toString();
    }

    public static JsonObject serializeBlockState(BlockState state) {
        Identifier id = Registry.BLOCK.getId(state.getBlock());
        JsonObject obj = new JsonObject();
        obj.addProperty("id", id.toString());
        for (Property prop : state.getProperties()) {
            if (prop instanceof BooleanProperty) {
                obj.addProperty(prop.getName(), state.get(prop).equals(Boolean.TRUE));
            } else if (prop instanceof IntProperty) {
                obj.addProperty(prop.getName(), Integer.parseInt(state.get(prop).toString()));
            } else {
                obj.addProperty(prop.getName(), state.get(prop).toString());
            }
        }
        return obj;
    }

    private static JsonObject serializeBlockState(HitResult target) {
        BlockPos pos = ((BlockHitResult) target).getBlockPos();
        BlockState state = mc.world.getBlockState(pos);
        JsonObject obj = serializeBlockState(state);
        obj.addProperty(
                "canPathfindThrough",
                state.canPathfindThrough(mc.world, pos, net.minecraft.entity.ai.pathing.NavigationType.LAND)
                );
        return obj;
    }

    public static void logEntity(Entity entity) {
        JsonObject obj = serializeEntity(entity);
        LOGGER.info(obj.toString());
    }

    public static JsonObject serializeEntity(Entity entity) {
        if ( entity == null ) return null;

        Identifier id = EntityType.getId(entity.getType());
        JsonObject obj = new JsonObject();
        obj.add("pos", Serializer.toJsonTree(entity.getPos()));
        obj.addProperty("speed", getSpeed(entity));
        obj.addProperty("yaw", MathHelper.wrapDegrees(entity.getYaw()));
        obj.addProperty("pitch", MathHelper.wrapDegrees(entity.getPitch()));
        obj.addProperty("id", id.toString());
        obj.addProperty("uuid", entity.getUuidAsString());
        obj.add("boundingBox", Serializer.toJsonTree(entity.getBoundingBox()));
        obj.add("visibilityBoundingBox", Serializer.toJsonTree(entity.getVisibilityBoundingBox()));
        obj.add("boundingCenter", Serializer.toJsonTree(entity.getBoundingBox().getCenter()));
        obj.add("visibilityBoundingCenter", Serializer.toJsonTree(entity.getVisibilityBoundingBox().getCenter()));
        String name = null;
        if ( entity.getName() != null ) {
            obj.addProperty("name", name = entity.getName().getString());
        }
        String ename;
        if ( (ename = entity.getEntityName()) != null ) {
            if (!ename.equals(entity.getUuidAsString()) && !ename.equals(name))
                obj.addProperty("entity_name", ename);
        }
        if ( entity.getCustomName() != null && !entity.getCustomName().getString().equals(name) ) {
            obj.addProperty("custom_name", entity.getCustomName().getString());
        }
        if ( entity.getDisplayName() != null && !entity.getDisplayName().getString().equals(name) ) {
            obj.addProperty("display_name", entity.getDisplayName().getString());
        }
        if (entity instanceof LivingEntity) {
            LivingEntity le = (LivingEntity) entity;
//            obj.addProperty("health", le.getHealth());
//            obj.addProperty("max_health", le.getMaxHealth());
// always meaningless or zero
//            obj.addProperty("lastAttackTime", le.getLastAttackTime());
//            obj.addProperty("lastAttackedTime", le.getLastAttackedTime());
//            obj.add("lastDamageSource", Serializer.toJsonTree(le.getRecentDamageSource()));
        }
        if (entity instanceof HostileEntity) {
            HostileEntity he = (HostileEntity) entity;
            obj.addProperty("isAngryAtPlayer", he.isAngryAt(mc.player));
        }
        if (entity instanceof MobEntity) {
            MobEntity mob = (MobEntity) entity;
            obj.add("target", Serializer.toJsonTree(mob.getTarget()));
            obj.addProperty("isAttacking", mob.isAttacking());
        }
        OpenNbtCompound nbt = new OpenNbtCompound();
        entity.writeNbt(nbt);
        if ( nbt.getSize() > 0 )
            obj.add("nbt", nbt.asJson());
        return obj;
    }

    public static JsonObject serializePlayerLookingAt(HitResult target) {
        JsonObject obj = new JsonObject();
        if ( target != null ) {
            Vec3d tpos = target.getPos();
            if ( tpos != null ) {
                Vec3d ppos = mc.player.getPos();
                obj.add("pos", Serializer.toJsonTree(tpos));
                obj.addProperty("distanceXYZ", ppos.distanceTo(tpos));
                obj.addProperty("distanceXZ",  Math.sqrt(Math.pow(ppos.x-tpos.x, 2) + Math.pow(ppos.z-tpos.z, 2)));
            }
        }
        if ( target.getType() == HitResult.Type.BLOCK ) {
            obj.add("block", serializeBlockState(target));
        } else if ( target.getType() == HitResult.Type.ENTITY ) {
            Entity entity = ((EntityHitResult) target).getEntity();
            obj.add("entity", serializeEntity(entity));
        }
        return obj;
    }

    private JsonObject serializePlayer() {
        JsonObject obj = serializeEntity(mc.player);
        obj.add("looking_at", serializePlayerLookingAt(mc.crosshairTarget));
        obj.add("inventory", Serializer.toJsonTree(mc.player.getInventory()));
        obj.add("health", GSON.toJsonTree(statusBarTracker.getHealth()));
        obj.add("mana", GSON.toJsonTree(statusBarTracker.getMana()));
        obj.add("defense", GSON.toJsonTree(statusBarTracker.getDefense()));
        obj.add("skills", GSON.toJsonTree(XPInformation.getInstance().getSkillInfoMap()));
        return obj;
    }

    private JsonObject buildJson() {
        JsonObject obj = new JsonObject();
        if ( mc.player != null ) {
            obj.add("player", serializePlayer());
            obj.addProperty("biome", getBiomeId(mc.player.getPos()));
        }
        if ( locraw != null ) {
            obj.add("locraw", GSON.toJsonTree(locraw));
        }
        return obj;
    }

    public static Entity getEntityFromUUID(UUID uuid) {
        for (Entity entity : mc.world.getEntities()) {
            if (entity.getUuid().equals(uuid)) {
                return entity;
            }
        }
        return null;
    }

    public JsonObject object2json(String uuid) {
        JsonObject obj = new JsonObject();
        return obj;
    }

	@Override    
	public void handle(HttpExchange http) throws IOException {
        StopWatch stopwatch = StopWatch.createStarted();
        try {
            String body = "";
            int status = 200;

            try {
                String path = http.getRequestURI().getPath();

                JsonObject obj = null;
                if( path.startsWith("/entity/") ) {
                    Entity entity = getEntityFromUUID(UUID.fromString(path.substring(8)));
                    if ( entity != null ) {
                        obj = serializeEntity(entity);
                    } else {
                        status = 404;
                    }
                } else {
                    obj = buildJson();
                    obj.addProperty("processing_time", stopwatch.getTime());
                }

                if ( obj != null )
                    body = obj.toString();

                http.getResponseHeaders().set("Content-Type", "application/json");
            } catch (Exception e) {
                body = e.toString();
                status = 500;
            }

            byte[] bytes = body.getBytes();
            http.getResponseHeaders().set("X-Processing-Time", Long.toString(stopwatch.getTime()));
//            http.getResponseHeaders().set("Connection", "close");
            http.sendResponseHeaders(status, bytes.length);

            OutputStream os = http.getResponseBody();
            os.write(bytes);
            os.flush();
            os.close();
        } catch (Exception e) {
            LOGGER.error(e.toString());
        }
	}
}
