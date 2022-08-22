package net.fabricmc.example.handlers;

import net.fabricmc.example.*;
import net.fabricmc.example.mixin.*;

import baritone.api.BaritoneAPI;
import baritone.api.utils.Rotation;
import baritone.api.utils.RotationUtils;

import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpHandler;
import java.io.IOException;
import java.io.OutputStream;
import java.util.regex.Pattern;
import java.util.Optional;

import net.minecraft.client.gui.hud.ChatHudLine;
import net.minecraft.predicate.entity.EntityPredicates;
import net.minecraft.sound.SoundEvents;
import net.minecraft.block.AirBlock;
import net.minecraft.block.BlockState;
import net.minecraft.block.Blocks;
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
import net.minecraft.text.MutableText;
import net.minecraft.text.Text;
import net.minecraft.util.Identifier;
import net.minecraft.util.hit.BlockHitResult;
import net.minecraft.util.hit.HitResult;
import net.minecraft.util.Hand;
import net.minecraft.util.math.BlockPos;
import net.minecraft.util.math.Box;
import net.minecraft.util.math.MathHelper;
import net.minecraft.util.math.Vec3d;
import net.minecraft.util.registry.Registry;
import net.minecraft.util.registry.RegistryEntry;
import net.minecraft.util.math.random.Random;
import net.minecraft.scoreboard.Team;
import net.minecraft.item.ItemStack;
import net.minecraft.item.Items;
import net.minecraft.inventory.Inventory;
import net.minecraft.nbt.NbtInt;
import net.minecraft.nbt.NbtCompound;
import net.minecraft.client.sound.SoundInstance;
import net.minecraft.util.shape.VoxelShape;
import net.minecraft.util.shape.VoxelShapes;
import net.minecraft.util.math.Direction;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import org.apache.commons.lang3.time.StopWatch;

import java.io.UnsupportedEncodingException;
import java.io.InputStreamReader;
import java.util.*;
import java.util.stream.Collectors;
import java.util.concurrent.ThreadLocalRandom;

import java.lang.reflect.Type;
import com.google.gson.*;
import com.google.gson.reflect.TypeToken;

import net.fabricmc.example.ExampleMod;
import net.fabricmc.example.utils.*;
import net.minecraft.entity.mob.ZombieEntity;
import net.minecraft.entity.passive.CatEntity;

import net.minecraft.screen.slot.SlotActionType;
import net.minecraft.client.gui.screen.ingame.HandledScreen;
import net.minecraft.client.gui.screen.Screen;
import net.minecraft.screen.ScreenHandler;
import net.minecraft.screen.slot.Slot;
import net.minecraft.screen.GenericContainerScreenHandler;

import org.lwjgl.glfw.GLFW;

import net.fabricmc.loader.api.FabricLoader;
import net.fabricmc.loader.api.metadata.ModMetadata;

public class ActionHandler implements HttpHandler {
    public static final Logger LOGGER = LoggerFactory.getLogger("modid");
    private static ModConfig CONFIG = null;
    private static MinecraftClient mc;
    public static boolean suppressButtonRelease = false;

    public static String log = new String();

    private String body = new String();
    private static List<Pattern> spamPatterns = new ArrayList<Pattern>();

    private static int suspendOverlayUpdateUntilTick = 0;
    private static Text overlayMessage = null;

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
        CONFIG = ExampleMod.CONFIG;
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
        double dx = lookat.getX() - mc.player.getEyePos().getX();
        double dy = lookat.getY() - mc.player.getEyePos().getY();
        double dz = lookat.getZ() - mc.player.getEyePos().getZ();

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

        smoothSetPitchYaw(newPitch, newYaw, delay);
    }

    private static void smoothSetPitchYaw(double newPitch, double newYaw, int delay) {
        delay = Math.max( delay, CONFIG.minActionDelay );

        if ( delay > 0 ) {
            newYaw = canonicalizeYaw(newYaw);
            double yaw = canonicalizeYaw(mc.player.getYaw());

            // "2 -> 359" => "2 -> -1"
            if ( newYaw-yaw > 180 ) newYaw -= 360;
            // "359 -> 2" => "359 -> 362"
            if ( yaw-newYaw > 180 ) newYaw += 360;

            double pitch = mc.player.getPitch();
            int randomNum = ThreadLocalRandom.current().nextInt(10, 21);
            int nsteps = (int)Math.ceil(Math.abs(newYaw-yaw)/randomNum);

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
        if (target instanceof BlockHitResult) {
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
        public String stringArg2;
        public Vec3d target;
        public Box box;
        public int delay = 1000;
        public boolean boolArg = false;
        public float floatArg;
        public float floatArg2;
        public int intArg;
        public int intArg2;
        public long longArg;

        public Vec3d expand = null;
        public Vec3d offset = null;

        public String resultKey = null;

        public int x,y,color,ttl;

        public int delayNext = 0; // delay next action (ticks)
    }

    private <T extends LivingEntity> List<T> getLivingEntitiesByClassName(String type, Box box, boolean onlyAlive) throws ClassNotFoundException {
        Class<T> entityClass = Mappings.short2class(type);
        if ( entityClass == null )
            entityClass = (Class<T>)Class.forName(type); // might throw!

        return mc.world.getEntitiesByClass(entityClass, box, LivingEntity::isAlive);
    }

    private <T extends Entity> List<T> getEntitiesByClassName(String type, Box box, boolean onlyAlive) throws ClassNotFoundException {
        Class<T> entityClass = (Class<T>)Mappings.short2class(type);
        if ( entityClass == null )
            entityClass = (Class<T>)Class.forName(type); // might throw!

        if ( onlyAlive && LivingEntity.class.isAssignableFrom(entityClass) ) {
            return (List<T>)getLivingEntitiesByClassName(type, box, onlyAlive);
        } else {
            return mc.world.getEntitiesByClass(entityClass, box, EntityPredicates.VALID_ENTITY);
        }
    }

    private static Box boxFromAction( Action action ) {
        Box box = mc.player.getBoundingBox();
        if ( action.offset != null )
            box = box.offset(action.offset);
        if ( action.expand != null )
            box = box.expand(action.expand.getX(), action.expand.getY(), action.expand.getZ());
        return box;
    }

    int delayNextActionUntilTick = 0;

    // AntiAntiCheat :)
    private void actionDelay(int delayNext) {
        while ( ExampleMod.tick < delayNextActionUntilTick ) {
            try { Thread.sleep(50); } catch (InterruptedException e) {}
        }

        if ( delayNext == 0 ) {
            delayNext = ThreadLocalRandom.current().nextInt(
                    CONFIG.minActionDelay,
                    CONFIG.minActionDelay + CONFIG.maxRandomActionDelay
                    );
        }

        delayNextActionUntilTick = ExampleMod.tick + delayNext;
    }

    private void actionDelay() {
        actionDelay(0);
    }

    private ItemStack copyStack( Inventory inv, int slot_id) {
        ItemStack stack = inv.getStack(slot_id);
        NbtCompound nbt = stack.getNbt();
        if ( nbt == null || nbt.getInt("origSlot") == 0 ){
            if ( !stack.getItem().equals(Items.AIR) ) {
                stack.setSubNbt("origSlot", NbtInt.of(slot_id));
            }
        }
        return stack;
    }

    final static int SIDE_DOWN  =  1;
    final static int SIDE_UP    =  2;
    final static int SIDE_NORTH =  4;
    final static int SIDE_SOUTH =  8;
    final static int SIDE_WEST  = 16;
    final static int SIDE_EAST  = 32;

    static HashMap<Integer, Vec3d> BLOCK_SIDE_MULTIPLIERS = new HashMap<Integer, Vec3d>() {{
        put(SIDE_DOWN,  new Vec3d(0.5, 0, 0.5));
        put(SIDE_UP,    new Vec3d(0.5, 1, 0.5));
        put(SIDE_NORTH, new Vec3d(0.5, 0.5, 0));
        put(SIDE_SOUTH, new Vec3d(0.5, 0.5, 1));
        put(SIDE_WEST,  new Vec3d(0, 0.5, 0.5));
        put(SIDE_EAST,  new Vec3d(1, 0.5, 0.5));
    }};

    public boolean lookAtBlock( BlockPos pos, int delay, double blockReachDistance, int sides ){
        if ( blockReachDistance == 0 ) {
            blockReachDistance = mc.interactionManager.getReachDistance();
        }
        Optional<Rotation> r = Optional.empty();

        if ( sides == 0 ) {
            // any side
            r = RotationUtils.reachable( mc.player, pos, blockReachDistance );
        } else {
            // adapted from baritone.api.utils.RotationUtils
            boolean wouldSneak = false;
            BlockState state = mc.world.getBlockState(pos);
            VoxelShape shape = state.getCollisionShape(mc.world, pos); // not sure if getCollisionShape is the correct method here
            if (shape.isEmpty()) {
                shape = VoxelShapes.fullCube();
            }
            for(Iterator<Map.Entry<Integer, Vec3d>> it = BLOCK_SIDE_MULTIPLIERS.entrySet().iterator(); it.hasNext(); ) {
                Map.Entry<Integer, Vec3d> entry = it.next();
                if ( (sides & entry.getKey()) == 0 )
                    continue;

                Vec3d sideOffset = entry.getValue();
                double xDiff = shape.getMin(Direction.Axis.X) * sideOffset.x + shape.getMax(Direction.Axis.X) * (1 - sideOffset.x);
                double yDiff = shape.getMin(Direction.Axis.Y) * sideOffset.y + shape.getMax(Direction.Axis.Y) * (1 - sideOffset.y);
                double zDiff = shape.getMin(Direction.Axis.Z) * sideOffset.z + shape.getMax(Direction.Axis.Z) * (1 - sideOffset.z);
                r = RotationUtils.reachableOffset(
                        mc.player,
                        pos,
                        new Vec3d(pos.getX(), pos.getY(), pos.getZ()).add(xDiff, yDiff, zDiff),
                        blockReachDistance,
                        wouldSneak);

                if ( r.isPresent() ) {
                    // found!
                    break;
                }
            }
        }

        if ( r.isPresent() ) {
            actionDelay();
            smoothSetPitchYaw(r.get().getPitch(), r.get().getYaw(), delay);
            return true;
        } else {
            return false;
        }
    }

    private int doAction(HttpExchange http) throws UnsupportedEncodingException, ClassNotFoundException, IOException {
        StopWatch stopwatch = StopWatch.createStarted();
        if ( !http.getRequestMethod().equals("POST") ) {
            body = "I want POST";
            return 400;
        }

        String requestBody = new String(http.getRequestBody().readAllBytes(), "UTF-8");
        List<Action> script;

        try {
            script = GSON.fromJson(requestBody, new TypeToken<List<Action>>() {}.getType());
        } catch (com.google.gson.JsonSyntaxException e){
            body = e.toString() + "\n\n" + requestBody;
            return 500;
        }

        JsonObject jsonResult = new JsonObject();

        for( Action action : script ) {
            if (action.command.equals("blocksRelative"))
                action.command = "blocks";

            if ( action.resultKey == null )
                action.resultKey = action.command;;

            if ( action.command.equals("status") ) {
                // if intArg != 0 then it's a tick number and we should wait for a next one
                // (or just different)
                if ( action.intArg != 0 ) {
                    while ( ExampleMod.tick == action.intArg ) {
                        try { Thread.sleep(1); } catch (InterruptedException e) {}
                    }
                }
                StatusHandler.buildJson(jsonResult);
            } else if ( action.command.equals("lookAt") ) {
                lookAt(action.target, action.delay);

            } else if ( action.command.equals("lookAtBlock") ) {
                // floatArg - custom reach distance, default if 0
                // intArg   - acceptable sides of block
                double reachDistance = action.floatArg;
                int sides = action.intArg;
                    
                boolean r = lookAtBlock(new BlockPos(action.target), action.delay, reachDistance, sides);
                jsonResult.addProperty( action.command, r );

            } else if (action.command.equals("travel")) {
                // travel vector is relative to player!
                // so f.ex. positive Z is always 'forward'
                actionDelay();
                mc.player.travel(action.target);

//            } else if (action.command.equals("blocks")) {
//                BlockPos b1 = new BlockPos(action.box.minX, action.box.minY, action.box.minZ);
//                BlockPos b2 = new BlockPos(action.box.maxX, action.box.maxY, action.box.maxZ);
//
//                if ( !jsonResult.has(action.resultKey) ) jsonResult.add(action.resultKey, new JsonArray());
//                JsonArray arr = jsonResult.getAsJsonArray(action.resultKey);
//
//                for( BlockPos pos : BlockPos.iterate(b1, b2)) {
//                    BlockState state = mc.world.getBlockState(pos);
//                    if ( state.getBlock() instanceof AirBlock )
//                        continue;
//                    JsonObject x = StatusHandler.serializeBlockState(state);
//                    x.add("pos", Serializer.toJsonTree((BlockPos)pos));
//                    arr.add(x);
//                }
            } else if (action.command.equals("blocks")) {
                // relative to player
                // arguments:
                //    Vec3d offset - box offset
                //    Vec3d expand - expand factor
                EntityCache.cleanup(mc);

                Box box = boxFromAction(action);
                jsonResult.add("box", Serializer.toJsonTree(box));

                if ( !jsonResult.has(action.resultKey) ) jsonResult.add(action.resultKey, new JsonArray());
                JsonArray arr = jsonResult.getAsJsonArray(action.resultKey);

                BlockPos.stream(box).forEach( pos -> {
                    BlockState state = mc.world.getBlockState(pos);
                    if ( (state.getBlock() instanceof AirBlock) && state.getProperties().isEmpty() ) {
                        // skip
                    } else {
                        JsonObject x = StatusHandler.serializeBlockState(state);
                        x.add("pos", Serializer.toJsonTree(pos));
                        arr.add(x);
                    }
                });
            } else if (action.command.equals("mine")) {
                actionDelay();
                mine(action.delay);
            } else if (action.command.equals("logs")) {
                body = log;
                log = new String();
                return 200;
            } else if (action.command.equals("key")) {
                actionDelay();
                pressKey(action.stringArg, action.delay);
//            } else if (action.command.equals("ai")) {
//                body = ai(action.target) ? "true" : "false";
//                return 200;
            } else if (action.command.equals("say")) {
                if ( action.stringArg != null ){
                    mc.player.sendMessage(Text.literal(action.stringArg));
                }

            } else if (action.command.equals("chat")) {
                if ( action.stringArg != null ){
                    mc.player.sendChatMessage(action.stringArg, null);
                }

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

            } else if (action.command.equals("selectSlot")) {
                if ( mc.player.getInventory().selectedSlot != action.intArg ){
                    actionDelay();
                    mc.player.getInventory().selectedSlot = action.intArg;
                }
            } else if (action.command.equals("sleep")) {
                try { Thread.sleep(action.delay); } catch (InterruptedException e) {}

            } else if (action.command.equals("registerCommand")) {
                ExampleMod.registerCommand(action.stringArg);
//            } else if (action.command.equals("getMobs")) {
//                // DEPRECATED
//                cleanupCache();
//                Vec3d pos = mc.player.getPos();
//                List<PathAwareEntity> l = mc.world.getEntitiesByClass(PathAwareEntity.class, action.box, LivingEntity::isAlive);
//                JsonObject obj = new JsonObject();
//                JsonArray mobs = new JsonArray();
//                for ( PathAwareEntity e : l ) {
//                    mobs.add(StatusHandler.serializeEntity(e));
//                    EntityCache.put(e.getUuid(), e);
//                }
//                obj.add("mobs", mobs);
//                obj.add("player", StatusHandler.serializePlayerCompact());
//                body = GSON.toJson(obj);
//                return 200;
            } else if (action.command.equals("entities")) {
                // relative to player
                // arguments:
                //    stringArg    - fully qualified entity name, like "net.minecraft.entity.LivingEntity"
                //    Vec3d offset - box offset
                //    Vec3d expand - expand factor
                //    bool boolArg - also return dead entites, if applicable (default: false)
                EntityCache.cleanup(mc);

                Box box = boxFromAction(action);
                jsonResult.add("box", Serializer.toJsonTree(box));
                List<Entity> entities;

                if ( action.stringArg == null || action.stringArg.equals("") )
                    action.stringArg = "Entity";

                entities = getEntitiesByClassName(action.stringArg, box, !action.boolArg);

                if ( !jsonResult.has(action.resultKey) ) jsonResult.add(action.resultKey, new JsonArray());
                JsonArray jentities = jsonResult.getAsJsonArray(action.resultKey);

                for ( Entity e : entities ) {
                    if ( e == mc.player )
                        continue;
                    jentities.add(StatusHandler.serializeEntity(e));
                    if ( e instanceof LivingEntity && e.isAlive())
                        EntityCache.put(e);
                }
            } else if (action.command.equals("clickScreenSlot")) {
                // intArg    slot_id
                // intArg2   button
                // stringArg actionType
                if ( mc.currentScreen == null || !(mc.currentScreen instanceof HandledScreen) )
                    return 400;

                int slotId = action.intArg;
                int button = action.intArg2;
                SlotActionType actionType = SlotActionType.valueOf(action.stringArg);

                HandledScreen screen = (HandledScreen)mc.currentScreen;
                if (slotId >= screen.getScreenHandler().slots.size() || slotId < -1 )
                    return 400;

                Slot slot = slotId == -1 ? null : screen.getScreenHandler().getSlot(slotId);
                ((ContainerAccessor)screen).invokeOnMouseClick(slot, slotId, button, actionType);

            } else if (action.command.equals("clickScreen")) {
                if ( mc.currentScreen == null )
                    return 400;
                HudOverlay.clickX = action.x;
                HudOverlay.clickY = action.y;
                HudOverlay.shouldClick = true;

            } else if (action.command.equals("clickSlot")) {
                // click on player inventory slot (can be done even if inventory screen is not open!)
                //
                // intArg    slot_id
                // intArg2   button
                // stringArg actionType
                int slotId = action.intArg;
                int button = action.intArg2;
                SlotActionType actionType = SlotActionType.valueOf(action.stringArg);
                if (slotId >= mc.player.getInventory().size())
                    return 400;
                mc.interactionManager.clickSlot(0, slotId, button, actionType, mc.player);

            } else if (action.command.equals("getEntityByUUID")) {
                UUID uuid = UUID.fromString(action.stringArg);
                Entity entity = EntityCache.get(uuid);
                if ( action.resultKey.equals("getEntityByUUID")) action.resultKey = "entity";
                jsonResult.add(action.resultKey, StatusHandler.serializeEntity(entity));

            } else if (action.command.equals("log")) {
                LOGGER.info(action.stringArg);
            } else if (action.command.equals("setPitch")) {
                if ( mc.player.getPitch() != action.floatArg ){
                    actionDelay();
                    mc.player.setPitch(action.floatArg);
                }
            } else if (action.command.equals("setYaw")) {
                if ( mc.player.getYaw() != action.floatArg ) {
                    actionDelay();
                    mc.player.setYaw(action.floatArg);
                }
            } else if (action.command.equals("setPitchYaw")) {
                if ( (mc.player.getPitch() != action.floatArg) || (mc.player.getYaw() != action.floatArg2) ) {
                    actionDelay();
                    smoothSetPitchYaw(action.floatArg, action.floatArg2, action.delay);
                }
            } else if (action.command.equals("dropSelectedItem")) {
                boolean entireStack = action.boolArg;
                actionDelay();
                mc.player.dropSelectedItem(entireStack);

            } else if (action.command.equals("closeHandledScreen")) {
                mc.player.closeHandledScreen();

            } else if (action.command.equals("closeScreen")) {
                // boolArg - wait for close
                if ( mc.currentScreen != null ) {
                    ExampleMod.shouldCloseScreen = true;
                    if ( action.boolArg ) {
                        while ( ExampleMod.shouldCloseScreen ) {
                            try { Thread.sleep(1); } catch (InterruptedException e) {}
                        }
                    }
                }
//            } else if (action.command.equals("Screen.setSlotXY")) {
//                if ( mc.currentScreen != null && mc.currentScreen instanceof HandledScreen ) {
//                    HandledScreen screen = (HandledScreen)mc.currentScreen;
//                    ScreenHandler handler = screen.getScreenHandler();
////                    Slot slot = handler.slots.get(action.intArg);
////                    if ( slot != null ) {
////                        handler.slots.set(action.intArg2, new Slot(slot.inventory, slot.getIndex(), action.x, action.y));
//                        handler.getStacks().set(action.intArg2, handler.getStacks().get(action.intArg));
////                    }
//                }

            } else if (action.command.equals("Screen.copySlot")) {
                if ( mc.currentScreen != null && mc.currentScreen instanceof HandledScreen ) {
                    HandledScreen screen = (HandledScreen)mc.currentScreen;
                    ScreenHandler handler = screen.getScreenHandler();
                    if ( handler instanceof GenericContainerScreenHandler ) {
                        GenericContainerScreenHandler gh = (GenericContainerScreenHandler)handler;
                        Inventory inv = gh.getInventory();
                        inv.setStack(action.intArg2, copyStack( inv, action.intArg));
                    }
                }

            } else if (action.command.equals("Screen.swapSlots")) {
                if ( mc.currentScreen != null && mc.currentScreen instanceof HandledScreen ) {
                    HandledScreen screen = (HandledScreen)mc.currentScreen;
                    ScreenHandler handler = screen.getScreenHandler();
                    if ( handler instanceof GenericContainerScreenHandler ) {
                        GenericContainerScreenHandler gh = (GenericContainerScreenHandler)handler;
                        Inventory inv = gh.getInventory();

                        ItemStack st1 = copyStack(gh.getInventory(), action.intArg);
                        ItemStack st2 = copyStack(gh.getInventory(), action.intArg2);

                        gh.getInventory().setStack(action.intArg, st2);
                        gh.getInventory().setStack(action.intArg2, st1);
                    }
                }

//            } else if (action.command.equals("Screen.setSlotIndex")) {
//                if ( mc.currentScreen != null && mc.currentScreen instanceof HandledScreen ) {
//                    HandledScreen screen = (HandledScreen)mc.currentScreen;
//                    ScreenHandler handler = screen.getScreenHandler();
//                    Slot slot = handler.slots.get(action.intArg);
//                    if ( slot != null ) {
//                        handler.slots.set(action.intArg, new Slot(slot.inventory, action.intArg2, slot.x, slot.y));
//                    }
//                }

            } else if (action.command.equals("messages")) {
                // stringArg   filter (regexp)
                jsonResult.add("messages", findMessages(action.stringArg));
            } else if (action.command.equals("attack")) {
                boolean r;
                try {
                    actionDelay();
                    r = ((MinecraftClientAccessor)mc).invokeDoAttack();
                } catch (Exception e) {
                    r = false;
                }
                jsonResult.addProperty("attack", r);
            } else if (action.command.equals("lockCursor")) {
                if ( action.boolArg )
                    ExampleMod.shouldLockCursor = true;
                else
                    ExampleMod.shouldUnlockCursor = true;
            } else if (action.command.equals("outlineEntity")) {
                // stringArg  entity uuid
                // longArg    RGBA color or 0 to disable
                UUID uuid = UUID.fromString(action.stringArg);
                EntityCache.setExtra(uuid, EntityCache.OUTLINE_COLOR, action.longArg);
            } else if (action.command.equals("suppressButtonRelease")) {
                if ( !suppressButtonRelease && !action.boolArg ){
                    suppressButtonRelease = action.boolArg;
                    int button = action.intArg;
                    ((MouseAccessor)mc.mouse).invokeOnMouseButton(
                        mc.getWindow().getHandle(), button, GLFW.GLFW_RELEASE, 0);
                } else {
                    suppressButtonRelease = action.boolArg;
                }
            } else if (action.command.equals("getTeams")) {
                if ( mc.player != null ) {
                    JsonArray teams = new JsonArray();
                    for( Team team : mc.player.getScoreboard().getTeams() ){
                        JsonObject obj = new JsonObject();
                        obj.addProperty("name", team.getName());
                        obj.addProperty("displayName", team.getDisplayName().getString());
                        obj.addProperty("prefix", team.getPrefix().getString());
                        obj.addProperty("suffix", team.getSuffix().getString());
                        obj.addProperty("nameTagVisibilityRule", String.valueOf(team.getNameTagVisibilityRule()));
                        obj.addProperty("nPlayers", team.getPlayerList().size());
                        teams.add(obj);
                    }
                    jsonResult.add("teams", teams);
                }
            } else if (action.command.equals("setTeamPrefix")) {
                if ( mc.player != null && action.stringArg != null && action.stringArg2 != null ) {
                    Team team = mc.player.getScoreboard().getTeam(action.stringArg);
                    if ( team != null ) {
                        team.setPrefix(Text.literal(action.stringArg2));
                    }
                }
            } else if (action.command.equals("setTeamSuffix")) {
                if ( mc.player != null && action.stringArg != null && action.stringArg2 != null ) {
                    Team team = mc.player.getScoreboard().getTeam(action.stringArg);
                    if ( team != null ) {
                        team.setSuffix(Text.literal(action.stringArg2));
                    }
                }

            } else if (action.command.equals("clearSpamFilters")) {
                spamPatterns.clear();

            } else if (action.command.equals("addSpamFilter")) {
                spamPatterns.add(Pattern.compile(action.stringArg));

            } else if (action.command.equals("getMods")) {
                JsonArray mods = new JsonArray();
                FabricLoader.getInstance().getAllMods()
                    .stream()
                    .forEach( mod -> {
                        mods.add(Serializer.toJsonTree(mod.getMetadata(), ModMetadata.class)) ;
                    });
                jsonResult.add("mods", mods);

            } else if (action.command.equals("HUD.addText")) {
                HudOverlay.addText(action.stringArg2, action.x, action.y, action.ttl, action.color, action.stringArg);

            } else if (action.command.equals("HUD.removeText")) {
                HudOverlay.removeText(action.stringArg2, action.x, action.y);

            } else if (action.command.equals("HUD.updateTextTTL")) {
                HudOverlay.updateTextTTL(action.stringArg2, action.x, action.y, action.ttl);

            } else if (action.command.equals("interactItem")) {
                Hand hand = action.intArg == 0 ? Hand.MAIN_HAND : Hand.OFF_HAND;
                actionDelay( action.delayNext );
                jsonResult.addProperty(
                        action.command,
                        mc.interactionManager.interactItem(mc.player, hand).toString()
                        );

            } else if (action.command.equals("interactBlock")) {
                HitResult target = mc.crosshairTarget;
                if (target instanceof BlockHitResult) {
                    Hand hand = action.intArg == 0 ? Hand.MAIN_HAND : Hand.OFF_HAND;
                    actionDelay( action.delayNext );
                    jsonResult.addProperty(
                            action.command,
                            mc.interactionManager.interactBlock(mc.player, hand, (BlockHitResult)target).toString()
                            );
                    mc.player.swingHand(Hand.MAIN_HAND);
                }

            } else if (action.command.equals("updateBlockBreakingProgress")) {
                HitResult target = mc.crosshairTarget;
                if (target instanceof BlockHitResult) {
                    actionDelay( action.delayNext );
                    jsonResult.addProperty(
                            action.command,
                            mc.interactionManager.updateBlockBreakingProgress(
                                ((BlockHitResult)target).getBlockPos(),
                                ((BlockHitResult)target).getSide()
                                )
                            );
                    mc.player.swingHand(Hand.MAIN_HAND);
                }

            } else if (action.command.equals("setOverlayMessage")) {
                // intArg - prevent overlay update for N ticks
                if ( action.intArg > 0 ) {
                    suspendOverlayUpdateUntilTick = ExampleMod.tick + action.intArg;
                }
                overlayMessage = Text.literal(action.stringArg);
                boolean tinted = action.boolArg;
                mc.inGameHud.setOverlayMessage( overlayMessage, tinted );

            } else if (action.command.equals("raytrace")) {
                HitResult target = mc.crosshairTarget;
                if ( target == null || target.getType() == HitResult.Type.MISS ) {
                    boolean useLiquids = action.boolArg;
                    double distance = action.floatArg;
                    target = RayTraceUtils.getRayTraceFromEntity(mc.world, mc.player, useLiquids, distance);
                }
                jsonResult.add( action.resultKey, StatusHandler.serializeHitResult(target) );

            } else if (action.command.equals("hideEntity")) {
                UUID uuid = UUID.fromString(action.stringArg);
                EntityCache.setExtra(uuid, EntityCache.HIDE_ENTITY, 1);

            } else if (action.command.equals("hideBlock")) {
                if ( action.target == null ) return 400;
                BlockPos pos = new BlockPos(action.target);
                if ( mc.world.getBlockState(pos) != null ) {
                    mc.world.setBlockState(pos, Blocks.AIR.getDefaultState(), 0, 0);
                }
//                mc.interactionManager.breakBlock(new BlockPos(action.target));
                // xz
//                actionDelay();
//                ((MinecraftClientAccessor)mc).invokeHandleBlockBreaking(action.boolArg);

            } else if (action.command.equals("setEntityExtra")) {
                UUID uuid = UUID.fromString(action.stringArg);
                EntityCache.setExtra(uuid, action.intArg, action.longArg);

            } else if (action.command.equals("clearExtras")) {
                EntityCache.clearExtras();

            } else if (action.command.equals("getSounds")) {
                int prev_index = action.intArg;
                jsonResult.add("sounds", SoundLog.serialize(prev_index));

            } else if (action.command.equals("hideOtherPlayers")) {
                EntityCache.setHideOtherPlayers(action.boolArg);

            } else {
                LOGGER.error("[?] invalid action: " + action.command);
            }
        }

        if( !jsonResult.has("tick") ){
            jsonResult.addProperty("tick", ExampleMod.tick);
        }
        
        if( !jsonResult.has("status") ){
            jsonResult.add("player", StatusHandler.serializePlayerCompact());
            jsonResult.addProperty("status", "compact");
        }
        jsonResult.addProperty("processing_time", stopwatch.getTime());
        body = GSON.toJson(jsonResult);
        return 200;
    }

    public static JsonArray findMessages(String filter) {
        Pattern pattern = Pattern.compile(filter);
        JsonArray arr = new JsonArray();
        for ( ChatHudLine line : ((MessagesAccessor)mc.inGameHud.getChatHud()).getMessages() ) {
            if ( pattern.matcher(line.content().getString()).find()) {
                arr.add(net.minecraft.text.Text.Serializer.toJsonTree(line.content()));
            }
        }
        return arr;
    }

	@Override
	public void handle(HttpExchange http) throws IOException {
        StopWatch stopwatch = StopWatch.createStarted();
        try {
            int status;

            try {
                status = doAction(http);
            } catch (Exception e) {
                body = e + "\n\n";
                for ( java.lang.StackTraceElement t : e.getStackTrace() ){
                    body += "  " + t + "\n";
                }
                status = 500;
            }

            byte[] bytes = body.getBytes();
            http.getResponseHeaders().set("X-Processing-Time", Long.toString(stopwatch.getTime()));
//            http.getResponseHeaders().set("Connection", "close");

            if ( status == 204 ) {
                http.sendResponseHeaders(status, -1);
            } else {
                http.sendResponseHeaders(status, bytes.length);
                OutputStream os = http.getResponseBody();
                os.write(bytes);
                os.flush();
                os.close();
            }
        } catch (Exception e) {
            LOGGER.error(e.toString());
        }
	}

    public static boolean shouldHideMessage( boolean isOverlay, String msg ){
        if ( isOverlay ) {
            if ( suspendOverlayUpdateUntilTick > ExampleMod.tick ) {
                return true;
            }
        } else {
            for ( Pattern p : spamPatterns ) {
                if ( p.matcher(msg).find() )
                    return true;
            }
        }
        return false;
    }

    public static boolean shouldMuteSound( SoundInstance sound ) {
        return false;
    }
}
