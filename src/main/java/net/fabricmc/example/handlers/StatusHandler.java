package net.fabricmc.example.handlers;

import net.fabricmc.example.*;
import net.fabricmc.example.mixin.*;

import net.fabricmc.example.OpenNbtCompound;
import net.fabricmc.example.utils.*;
import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpHandler;
import java.io.IOException;
import java.io.OutputStream;
import java.io.ByteArrayOutputStream;
import java.io.DataOutputStream;
import java.io.FileOutputStream;
import java.util.*;

import net.minecraft.block.BlockState;
import net.minecraft.client.MinecraftClient;
import net.minecraft.entity.Entity;
import net.minecraft.entity.EntityType;
import net.minecraft.block.entity.BlockEntityType;
import net.minecraft.entity.LivingEntity;
import net.minecraft.entity.mob.MobEntity;
import net.minecraft.entity.player.PlayerEntity;
import net.minecraft.entity.mob.HostileEntity;
import net.minecraft.inventory.Inventory;
import net.minecraft.item.ItemStack;
import net.minecraft.state.property.BooleanProperty;
import net.minecraft.state.property.IntProperty;
import net.minecraft.state.property.Property;
import net.minecraft.util.Identifier;
import net.minecraft.util.hit.BlockHitResult;
import net.minecraft.util.hit.EntityHitResult;
import net.minecraft.util.hit.HitResult;
import net.minecraft.util.math.BlockPos;
import net.minecraft.util.math.Direction;
import net.minecraft.util.math.MathHelper;
import net.minecraft.util.registry.Registry;
import net.minecraft.util.math.Vec3d;
import net.minecraft.util.Formatting;
import net.minecraft.scoreboard.*;
import net.minecraft.nbt.NbtCompound;
import net.minecraft.text.Text;
import net.minecraft.world.World;
import net.minecraft.block.entity.BlockEntity;
import net.minecraft.entity.decoration.ArmorStandEntity;
import net.minecraft.client.gui.hud.ClientBossBar;

import com.google.gson.JsonArray;
import com.google.gson.JsonObject;
import com.google.gson.Gson;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import org.apache.commons.lang3.time.StopWatch;
import java.util.UUID;

import net.minecraft.client.gui.screen.ingame.HandledScreen;
import net.minecraft.client.gui.Element;
import net.minecraft.client.gui.screen.Screen;
import net.minecraft.screen.ScreenHandler;
import net.minecraft.screen.slot.Slot;
import net.minecraft.client.gui.widget.*;

public class StatusHandler implements HttpHandler {
    public static final Logger LOGGER = LoggerFactory.getLogger("modid");
    private static ModConfig CONFIG = null;
    private static MinecraftClient mc;
    private static final Gson GSON = new Gson();
    public static Locraw locraw;
    public static final StatusBarTracker statusBarTracker = new StatusBarTracker();
    private static HashMap<String, InputEvent> inputEvents = new HashMap<String, InputEvent>();
    private static HashMap<Integer, String> commands = new HashMap<Integer, String>();
    private static String overlay;

	public StatusHandler(MinecraftClient mc) {
	    StatusHandler.mc = mc;
        CONFIG = ExampleMod.CONFIG;
	}

    public static void onCommand(String command){
        commands.put(ExampleMod.tick, command);
    }

    public static void logInputEvent(String name, int state) {
        InputEvent e = inputEvents.get(name);
        if ( e != null ) {
            if ( e.state == state ) {
                e.age++;
            } else {
                e.state = state;
                e.age = 0;
            }
        } else {
            inputEvents.put(name, new InputEvent(state));
        }
    }

    static class InputEvent {
        int state;
        int age = 0;

        InputEvent(int state) {
            this.state = state;
        }
    }

    // {"server":"mini31CG","gametype":"SKYBLOCK","mode":"foraging_1","map":"The Park"}
    public class Locraw {
        public String server;
        String gametype;
        String mode;
        String map;
    }

    public static void handleMessage(boolean isOverlay, String msg) {
        if (isOverlay) {
            overlay = msg;
            statusBarTracker.update(msg, false);
            XPInformation.getInstance().onChatReceived(msg);
        } else if (msg.startsWith("{") && msg.endsWith("}")) {
            setLocraw(msg);
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

// exceptions when teleporting between islands
//    private static String getBiomeId(Vec3d pos) {
//        return mc.world.getRegistryManager().
//            get(Registry.BIOME_KEY).
//            getId(mc.world.getBiome(new BlockPos(pos)).value()).
//            toString();
//    }

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
        if ( CONFIG.experimental ) {
            obj.add( "tags", Serializer.toJsonTree( state.streamTags().toList() ));
            obj.addProperty( "isAir", state.isAir());
            //obj.addProperty( "isSolidBlock", state.isSolidBlock());
        }
        return obj;
    }

    private static JsonObject serializeBlockEntity(BlockEntity be) {
        JsonObject obj = new JsonObject();
        Identifier id = BlockEntityType.getId(be.getType());
        obj.addProperty("id", id.toString());
        obj.add("nbt", OpenNbtCompound.toJson(be.createNbt()));
        return obj;
    }

    private static JsonObject serializeBlockState(HitResult target) {
        BlockPos pos = ((BlockHitResult) target).getBlockPos();
        Direction side = ((BlockHitResult) target).getSide();
        BlockState state = mc.world.getBlockState(pos);
        JsonObject obj = serializeBlockState(state);
        obj.add( "pos", Serializer.toJsonTree(pos) );
        obj.addProperty( "side", side.getName());
        obj.addProperty(
                "canPathfindThrough",
                state.canPathfindThrough(mc.world, pos, net.minecraft.entity.ai.pathing.NavigationType.LAND)
                );
        obj.addProperty( "hardness", state.getBlock().getHardness() );
        obj.addProperty( "canHarvest", mc.player.canHarvest(state) );
        obj.addProperty( "blockBreakingSpeed", mc.player.getBlockBreakingSpeed(state) );

        BlockEntity be = mc.world.getBlockEntity(pos);
        if ( be != null ) {
            obj.add( "blockEntity", serializeBlockEntity(be));
        }

        return obj;
    }

    public static void logEntity(Entity entity) {
        JsonObject obj = serializeEntity(entity);
        LOGGER.info(obj.toString());
    }

    public static JsonObject serializeEntityCompact(Entity entity) {
        if ( entity == null ) return null;

        Identifier id = EntityType.getId(entity.getType());
        JsonObject obj = new JsonObject();
        obj.addProperty("id", id.toString()); // historically...
        obj.addProperty("network_id", entity.getId());
        obj.addProperty("class", entity.getClass().getName());
        obj.addProperty("classShort", Mappings.class2short(entity.getClass()));
        obj.add("pos", Serializer.toJsonTree(entity.getPos()));
        obj.add("eyePos", Serializer.toJsonTree(entity.getEyePos()));
        obj.addProperty("uuid", entity.getUuidAsString());
        obj.addProperty("canHit", entity.canHit());
        obj.addProperty("horizontalFacing", entity.getHorizontalFacing().getName());


        String name = null;
        if ( !(entity instanceof ArmorStandEntity) ){
            // hypixel custom entity name magick
            Entity nameEntity = mc.world.getEntityById( entity.getId() + 1 );
            if ( (nameEntity instanceof ArmorStandEntity) && (nameEntity.getName() != null) ) {
                name = nameEntity.getName().getString();
            }
        }
        if ( name == null && entity.getName() != null ) {
            name = entity.getName().getString();
        }
        obj.addProperty("name", name);

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

        obj.add("boundingCenter", Serializer.toJsonTree(entity.getBoundingBox().getCenter()));
        obj.add("visibilityBoundingCenter", Serializer.toJsonTree(entity.getVisibilityBoundingBox().getCenter()));

        long outlineColor = EntityCache.getExtra(entity.getUuid(), EntityCache.OUTLINE_COLOR);
        if ( outlineColor != 0 ) {
            obj.addProperty("outlineColor", outlineColor);
        }

        obj.addProperty("distance", entity.distanceTo(mc.player));

        return obj;
    }

    public static JsonObject serializeEntity(Entity entity) {
        return serializeEntity(entity, new HashSet<Entity>());
    }

    public static JsonObject serializeEntity(Entity entity, Set<Entity> serializedEntities) {
        if ( entity == null ) return null;

        EntityCache.put(entity);

        JsonObject obj = serializeEntityCompact(entity);
        if ( serializedEntities.contains(entity) ){
            // prevent infinite loop & stack overflow
            return obj;
        }
        serializedEntities.add(entity);

        obj.addProperty("pose", entity.getPose().toString());
        obj.addProperty("speed", getSpeed(entity));
        obj.addProperty("yaw", MathHelper.wrapDegrees(entity.getYaw()));
        obj.addProperty("pitch", MathHelper.wrapDegrees(entity.getPitch()));
        // causes 'Accessing LegacyRandomSource from multiple threads' exception
//        obj.addProperty("randomBodyY", entity.getRandomBodyY());
        obj.add("boundingBox", Serializer.toJsonTree(entity.getBoundingBox()));
//        obj.add("visibilityBoundingBox", Serializer.toJsonTree(entity.getVisibilityBoundingBox()));
        if (entity instanceof LivingEntity) {
            LivingEntity le = (LivingEntity) entity;
            obj.addProperty("alive", le.isAlive());
            obj.add("attacking", serializeEntity(le.getAttacking(), serializedEntities));
//            obj.addProperty("activeEyeHeight", ((LivingEntityAccessor)le).invokeGetActiveEyeHeight(le.getPose(), le.getDimensions(le.getPose())));
//            obj.addProperty("health", le.getHealth());
//            obj.addProperty("max_health", le.getMaxHealth());
// always meaningless or zero
            obj.addProperty("lastAttackTime", le.getLastAttackTime());
            obj.addProperty("lastAttackedTime", le.getLastAttackedTime());
            obj.add("lastDamageSource", Serializer.toJsonTree(le.getRecentDamageSource()));
        }
//        always true
//        if (entity instanceof HostileEntity) {
//            HostileEntity he = (HostileEntity) entity;
//            obj.addProperty("isAngryAtPlayer", he.isAngryAt(mc.player));
//        }
//
//        // always empty
//        if (entity instanceof MobEntity) {
//            MobEntity mob = (MobEntity) entity;
//            obj.add("target", Serializer.toJsonTree(mob.getTarget()));
//            obj.addProperty("isAttacking", mob.isAttacking());
//        }
        if ( entity.isRemoved() )
            obj.addProperty("removed", true);

        Set<String> scoreboardTags = entity.getScoreboardTags();
        if ( scoreboardTags != null && scoreboardTags.size() > 0 ) {
            obj.add("scoreboardTags", Serializer.toJsonTree(scoreboardTags));
        }

        AbstractTeam team = entity.getScoreboardTeam();
        if ( team != null ) {
            obj.addProperty("scoreboardTeam", team.getName());
        }

        OpenNbtCompound nbt = new OpenNbtCompound();
        entity.writeNbt(nbt);
        if ( nbt.getSize() > 0 )
            obj.add("nbt", nbt.asJson());

        return obj;
    }

    public static JsonObject serializeHitResult(HitResult target) {
        if ( target == null ) return null;

        JsonObject obj = new JsonObject();
        Vec3d tpos = target.getPos();
        if ( tpos != null ) {
            Vec3d epos = mc.player.getEyePos();
            obj.add("pos", Serializer.toJsonTree(tpos));
            obj.addProperty("distance", epos.distanceTo(tpos));
        }
        if ( target.getType() == HitResult.Type.BLOCK ) {
            obj.add("block", serializeBlockState(target));
        } else if ( target.getType() == HitResult.Type.ENTITY ) {
            Entity entity = ((EntityHitResult) target).getEntity();
            obj.add("entity", serializeEntity(entity));
        }
        return obj;
    }

    public static JsonObject serializePlayerCompact() {
        if (mc == null || mc.player == null) return null;
        JsonObject obj = serializeEntityCompact(mc.player);
        obj.add("chunkPos", GSON.toJsonTree(mc.player.getChunkPos()));
        obj.add("defense", GSON.toJsonTree(statusBarTracker.getDefense()));
        obj.add("health", GSON.toJsonTree(statusBarTracker.getHealth()));
        obj.add("hotbar", Serializer.toJsonTree(mc.player.getInventory()));
        obj.add("mana", GSON.toJsonTree(statusBarTracker.getMana()));
        obj.add("skills", GSON.toJsonTree(XPInformation.getInstance().getSkillInfoMap()));
        obj.addProperty("abilityCharges", XPInformation.tickers);
        obj.addProperty("isBreakingBlock", BlockBreakHelper.isBreakingBlock() || mc.interactionManager.isBreakingBlock());
        obj.add("looking_at", serializeHitResult(mc.crosshairTarget));
        return obj;
    }

    public static JsonObject serializePlayer() {
        JsonObject obj = serializeEntity(mc.player);
        obj.add("chunkPos", GSON.toJsonTree(mc.player.getChunkPos()));
        obj.add("defense", GSON.toJsonTree(statusBarTracker.getDefense()));
        obj.add("fishHook", serializeEntity(mc.player.fishHook));
        obj.add("health", GSON.toJsonTree(statusBarTracker.getHealth()));
        obj.add("hotbar", Serializer.toJsonTree(mc.player.getInventory()));
        obj.add("inventory", serializeInventory(mc.player.getInventory()));
        obj.add("mana", GSON.toJsonTree(statusBarTracker.getMana()));
        obj.add("skills", GSON.toJsonTree(XPInformation.getInstance().getSkillInfoMap()));
        obj.addProperty("abilityCharges", XPInformation.tickers);
        obj.addProperty("experienceLevel", mc.player.experienceLevel);
        obj.addProperty("experienceProgress", mc.player.experienceProgress);
        obj.addProperty("reachDistance", mc.interactionManager.getReachDistance());
        obj.addProperty("isBreakingBlock", BlockBreakHelper.isBreakingBlock() || mc.interactionManager.isBreakingBlock());
        obj.add("looking_at", serializeHitResult(mc.crosshairTarget));
        return obj;
    }

    private static JsonArray serializeInventory(Inventory src) {
        return serializeInventory(src, 0);
    }

    public static JsonObject serializeItemStack(ItemStack stack) {
        return serializeItemStack(stack, 0);
    }

    public static JsonObject serializeItemStack(ItemStack stack, int flags) {
        if ( stack == null )
            return null;
        OpenNbtCompound nbt = new OpenNbtCompound();
        stack.writeNbt(nbt);
        JsonObject obj = nbt.asJson(flags);
        obj.addProperty("maxCount", stack.getMaxCount());
        return obj;
    }

    private static JsonArray serializeInventory(Inventory src, int flags) {
        if ( src == null ) return null;
        JsonArray arr = new JsonArray();
        if ( src.isEmpty() ) return arr;
        for ( int i=0; i<src.size(); i++ ) {
            arr.add(serializeItemStack(src.getStack(i), flags));
        }
        return arr;
    }

    public static String defaultToString(Object o) {
        return o.getClass().getName() + "@" + Integer.toHexString(o.hashCode());
    }

    private static JsonObject serializeSlot(Slot slot) {
        if ( slot == null ) return null;
        JsonObject obj = new JsonObject();
        obj.addProperty("id", slot.id);
        obj.addProperty("index", slot.getIndex());
        obj.addProperty("x", slot.x);
        obj.addProperty("y", slot.y);
        obj.addProperty("inventoryId", slot.inventory == mc.player.getInventory() ? "player" : defaultToString(slot.inventory));
        return obj;
    }

    private static JsonArray serializeScreenChildren(Screen screen) {
        JsonArray arr = new JsonArray();
        for ( Element e : screen.children() ){
            JsonObject obj = new JsonObject();
            obj.addProperty("class", e.getClass().getName());
            if ( e instanceof ClickableWidget ){
                ClickableWidget cw = (ClickableWidget)e;
                obj.addProperty("x", cw.x);
                obj.addProperty("y", cw.y);
                obj.addProperty("width", cw.getWidth());
                obj.addProperty("height", cw.getHeight());
                obj.addProperty("message", text2string(cw.getMessage()));
            }
            arr.add(obj);
        }
        return arr;
    }

    private static JsonObject serializeHandler(ScreenHandler handler) {
        JsonObject obj = new JsonObject();
        obj.addProperty("syncId", handler.syncId);
        obj.addProperty("class", handler.getClass().getName());
        obj.addProperty("revision", handler.getRevision());
        obj.add("cursorStack", serializeItemStack(handler.getCursorStack()));
        return obj;
    }

    private static JsonObject serializeScreen(Screen screen) {
        if ( screen == null ) return null;
        JsonObject obj = new JsonObject();
        obj.addProperty("class", screen.getClass().getName());
        obj.addProperty("classShort", Mappings.class2short(screen.getClass()));
        obj.addProperty("title", screen.getTitle().getString());
        obj.addProperty("width", screen.width);
        obj.addProperty("height", screen.height);
        if ( screen instanceof HandledScreen ) {
            obj.addProperty("x", ((ContainerAccessor)screen).getX());
            obj.addProperty("y", ((ContainerAccessor)screen).getY());
            ScreenHandler handler = ((HandledScreen)screen).getScreenHandler();
            obj.add("handler", serializeHandler(handler));
            JsonArray arr = new JsonArray();
            JsonObject inventories = new JsonObject();
            for ( Slot slot : handler.slots ) {
                arr.add(serializeSlot(slot));
                String inventoryId = defaultToString(slot.inventory);
                if ( !inventories.has(inventoryId) && slot.inventory != mc.player.getInventory() )
                    inventories.add(inventoryId, serializeInventory(slot.inventory, OpenNbtCompound.WITH_LORE));
            }
            obj.add("slots", arr);
            obj.add("inventories", inventories);
        }
        obj.add("children", serializeScreenChildren(screen));
        obj.addProperty("cursorDragging", screen.isDragging());
        return obj;
    }

    public static ArrayList<String> getPlayerList() {
        ArrayList<String> r = new ArrayList<String>();
        try {
            mc.getNetworkHandler().getPlayerList()
                .stream()
                .sorted((o1, o2)->o1.getProfile().getName().compareTo(o2.getProfile().getName()))
                .forEach( ple -> {
                    if ( ple.getDisplayName() != null ) {
                        r.add( Formatting.strip(ple.getDisplayName().getString()) );
                    }
                });
        } catch ( Exception e ) {
        }
        return r;
    }

    public static String getPlayerListFooter() {
        try {
            Text footer = ((PlayerListHudAccessor)mc.inGameHud.getPlayerListHud()).getFooter();
            if ( footer == null ) {
                return null;
            } else {
                return Formatting.strip(footer.getString());
            }
        } catch ( Exception e ) {
            return null;
        }
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
                    obj = getStatus(null);
                    obj.addProperty("tick_time", ExampleMod.tickStart.getTime());
                    obj.addProperty("processing_time", stopwatch.getTime());
                }

                if ( obj != null )
                    body = GSON.toJson(obj); // removes null values

                http.getResponseHeaders().set("Content-Type", "application/json");
            } catch (Exception e) {
                body = e + "\n\n";
                for ( java.lang.StackTraceElement t : e.getStackTrace() ){
                    body += "  " + t + "\n";
                }
                status = 500;
            }

            byte[] bytes = body.getBytes();
            http.getResponseHeaders().set("X-Processing-Time", Long.toString(stopwatch.getTime()));
            http.getResponseHeaders().set("Connection", "close");
            http.sendResponseHeaders(status, bytes.length);

            OutputStream os = http.getResponseBody();
            os.write(bytes);
            os.flush();
            os.close();
        } catch (Exception e) {
            LOGGER.error(e.toString());
        }
	}

    // from Skyblocker
    public static List<String> getSidebar() {
        try {
            if (mc.player == null) return null;
            Scoreboard scoreboard = mc.player.getScoreboard();
            ScoreboardObjective objective = scoreboard.getObjectiveForSlot(1);
            List<String> lines = new ArrayList<>();
            for (ScoreboardPlayerScore score : scoreboard.getAllPlayerScores(objective)) {
                Team team = scoreboard.getPlayerTeam(score.getPlayerName());
                if (team != null) {
                    String line = team.getPrefix().getString() + team.getSuffix().getString();
                    if (line.trim().length() > 0) {
                        lines.add(Formatting.strip(line));
                    }
                }
            }

            if (objective != null) {
                lines.add(objective.getDisplayName().getString());
                Collections.reverse(lines);
            }
            return lines;
        } catch (NullPointerException e) {
            return null;
        }
    }

    public static JsonObject serializeWorld(World world) {
        if ( world == null ) return null;
        JsonObject obj = new JsonObject();
        obj.addProperty("time", world.getTime());
        obj.addProperty("timeOfDay", world.getTimeOfDay());
        obj.addProperty("tickOrder", world.getTickOrder());
        obj.addProperty("ambientDarkness", world.getAmbientDarkness());
        return obj;
    }

    public static String text2string(Text text) {
        return (text == null) ? null : text.getString();
    }

    public static JsonObject serializeHUD() {
        JsonObject obj = new JsonObject();
        obj.addProperty("title", text2string(((InGameHudAccessor)mc.inGameHud).getTitle()));
        obj.addProperty("subtitle", text2string(((InGameHudAccessor)mc.inGameHud).getSubtitle()));
        return obj;
    }

    // main
    public static JsonObject getStatus(JsonObject obj) {
        if ( obj == null ) {
            obj = new JsonObject();
        }
        obj.addProperty("tick", ExampleMod.tick);
        if ( mc.player != null ) {
            obj.add("player", serializePlayer());
        }
        if ( mc.cameraEntity != null && mc.cameraEntity != mc.player ) {
            obj.add("camera", serializeEntity(mc.cameraEntity));
        }
        if ( locraw != null ) {
            obj.add("locraw", GSON.toJsonTree(locraw));
        }
        obj.add("screen", serializeScreen(mc.currentScreen));
        obj.add("sidebar", GSON.toJsonTree(getSidebar()));
        obj.add("input", GSON.toJsonTree(inputEvents));
        obj.add("commands", GSON.toJsonTree(commands));
        obj.addProperty("overlay", overlay);
        obj.add("playerList", GSON.toJsonTree(getPlayerList()));
        obj.addProperty("playerListFooter", getPlayerListFooter());
        obj.add("world", serializeWorld(mc.world));
        obj.add("hud", serializeHUD());
        obj.addProperty("status", "full");
        obj.addProperty("status", "full");
        obj.add("bossBars", Serializer.toJsonTree(
                    ((BossBarHudAccessor)mc.inGameHud.getBossBarHud()).getBossBars()
                    ));
        return obj;
    }

}
